#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REALM="${REALM:-mon0}"
SAUCE_REGION="${SAUCE_REGION:-us-west-1}"
APK_SOURCE="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
SAUCE_UPLOAD_DIR="$APP_DIR/build/sauce"
SAUCE_APP_NAME="${SAUCE_APP_NAME:-smart-cinema-$(date +%Y%m%d-%H%M%S).apk}"
APK_UPLOAD_PATH="$SAUCE_UPLOAD_DIR/$SAUCE_APP_NAME"
UPLOAD_RESPONSE="$APP_DIR/build/sauce_upload_response.json"

if [[ -z "${RUM_ACCESS_TOKEN:-}" ]]; then
  echo "RUM_ACCESS_TOKEN is required."
  echo "Example: REALM=mon0 RUM_ACCESS_TOKEN=<token> SAUCE_USERNAME=<user> SAUCE_ACCESS_KEY=<key> $0"
  exit 1
fi

if [[ -z "${SAUCE_USERNAME:-}" ]]; then
  echo "SAUCE_USERNAME is required."
  exit 1
fi

if [[ -z "${SAUCE_ACCESS_KEY:-}" ]]; then
  echo "SAUCE_ACCESS_KEY is required."
  exit 1
fi

case "$SAUCE_REGION" in
  us-west-1)
    SAUCE_STORAGE_URL="https://api.us-west-1.saucelabs.com/v1/storage/upload"
    ;;
  us-east-4)
    SAUCE_STORAGE_URL="https://api.us-east-4.saucelabs.com/v1/storage/upload"
    ;;
  eu-central-1)
    SAUCE_STORAGE_URL="https://api.eu-central-1.saucelabs.com/v1/storage/upload"
    ;;
  *)
    echo "Unsupported SAUCE_REGION: $SAUCE_REGION"
    echo "Supported values: us-west-1, us-east-4, eu-central-1"
    exit 1
    ;;
esac

cd "$APP_DIR"

echo "Building debug APK with realm $REALM..."
flutter build apk --debug \
  --dart-define=REALM="$REALM" \
  --dart-define=RUM_ACCESS_TOKEN="$RUM_ACCESS_TOKEN"

mkdir -p "$SAUCE_UPLOAD_DIR"
cp "$APK_SOURCE" "$APK_UPLOAD_PATH"

echo "Uploading $APK_UPLOAD_PATH to Sauce Labs App Storage..."
echo "Sauce region: $SAUCE_REGION"
curl -u "$SAUCE_USERNAME:$SAUCE_ACCESS_KEY" --location \
  --request POST "$SAUCE_STORAGE_URL" \
  --form "payload=@$APK_UPLOAD_PATH" \
  --form "name=$SAUCE_APP_NAME" \
  --output "$UPLOAD_RESPONSE" \
  --fail-with-body

echo
echo "Saved Sauce upload response to $UPLOAD_RESPONSE"
cat "$UPLOAD_RESPONSE"
echo
echo "Use this app capability in Sauce/Appium:"
echo "storage:filename=$SAUCE_APP_NAME"

if command -v jq >/dev/null 2>&1; then
  file_id="$(jq -r '.item.id // empty' "$UPLOAD_RESPONSE")"
  if [[ -n "$file_id" ]]; then
    echo "Or use this file id:"
    echo "storage:$file_id"
  fi
fi
