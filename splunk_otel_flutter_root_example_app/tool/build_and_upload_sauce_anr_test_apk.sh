#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REALM="${REALM:-mon0}"
SAUCE_REGION="${SAUCE_REGION:-us-west-1}"
ANR_BLOCK_SECONDS="${ANR_BLOCK_SECONDS:-15}"
TELEMETRY_SETTLE_SECONDS="${TELEMETRY_SETTLE_SECONDS:-180}"
TEST_TARGET="${TEST_TARGET:-integration_test/anr_test.dart}"
APP_APK_SOURCE="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
TEST_APK_SOURCE="$APP_DIR/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
SAUCE_UPLOAD_DIR="$APP_DIR/build/sauce"
SAUCE_APP_NAME="${SAUCE_APP_NAME:-smart-cinema-anr-$(date +%Y%m%d-%H%M%S).apk}"
SAUCE_TEST_APP_NAME="${SAUCE_TEST_APP_NAME:-splunk-cinema-anr-test-$(date +%Y%m%d-%H%M%S).apk}"
APP_APK_UPLOAD_PATH="$SAUCE_UPLOAD_DIR/$SAUCE_APP_NAME"
TEST_APK_UPLOAD_PATH="$SAUCE_UPLOAD_DIR/$SAUCE_TEST_APP_NAME"
APP_UPLOAD_RESPONSE="$APP_DIR/build/sauce_anr_app_upload_response.json"
TEST_UPLOAD_RESPONSE="$APP_DIR/build/sauce_anr_test_apk_upload_response.json"
ANDROID_STUDIO_JDK="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

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

if [[ -z "${JAVA_HOME:-}" && -x "$ANDROID_STUDIO_JDK/bin/java" ]]; then
  export JAVA_HOME="$ANDROID_STUDIO_JDK"
fi

echo "Building debug app APK with Flutter test target $TEST_TARGET..."
flutter build apk --debug \
  --target="$TEST_TARGET" \
  --dart-define=REALM="$REALM" \
  --dart-define=RUM_ACCESS_TOKEN="$RUM_ACCESS_TOKEN" \
  --dart-define=ANR_BLOCK_SECONDS="$ANR_BLOCK_SECONDS" \
  --dart-define=TELEMETRY_SETTLE_SECONDS="$TELEMETRY_SETTLE_SECONDS"

echo "Building Android instrumentation test APK..."
pushd android >/dev/null
./gradlew app:assembleAndroidTest
popd >/dev/null

if [[ ! -f "$APP_APK_SOURCE" ]]; then
  echo "App APK was not found at $APP_APK_SOURCE"
  exit 1
fi

if [[ ! -f "$TEST_APK_SOURCE" ]]; then
  echo "Test APK was not found at $TEST_APK_SOURCE"
  exit 1
fi

mkdir -p "$SAUCE_UPLOAD_DIR"
cp "$APP_APK_SOURCE" "$APP_APK_UPLOAD_PATH"
cp "$TEST_APK_SOURCE" "$TEST_APK_UPLOAD_PATH"

echo "Uploading $APP_APK_UPLOAD_PATH to Sauce Labs App Storage..."
echo "Sauce region: $SAUCE_REGION"
curl -u "$SAUCE_USERNAME:$SAUCE_ACCESS_KEY" --location \
  --request POST "$SAUCE_STORAGE_URL" \
  --form "payload=@$APP_APK_UPLOAD_PATH" \
  --form "name=$SAUCE_APP_NAME" \
  --output "$APP_UPLOAD_RESPONSE" \
  --fail-with-body

echo
echo "Saved Sauce app upload response to $APP_UPLOAD_RESPONSE"
cat "$APP_UPLOAD_RESPONSE"
echo

echo "Uploading $TEST_APK_UPLOAD_PATH to Sauce Labs App Storage..."
echo "Sauce region: $SAUCE_REGION"
curl -u "$SAUCE_USERNAME:$SAUCE_ACCESS_KEY" --location \
  --request POST "$SAUCE_STORAGE_URL" \
  --form "payload=@$TEST_APK_UPLOAD_PATH" \
  --form "name=$SAUCE_TEST_APP_NAME" \
  --output "$TEST_UPLOAD_RESPONSE" \
  --fail-with-body

echo
echo "Saved Sauce test APK upload response to $TEST_UPLOAD_RESPONSE"
cat "$TEST_UPLOAD_RESPONSE"
echo
echo "Use these capabilities in Sauce/saucectl:"
echo "app: storage:filename=$SAUCE_APP_NAME"
echo "testApp: storage:filename=$SAUCE_TEST_APP_NAME"

if command -v jq >/dev/null 2>&1; then
  app_file_id="$(jq -r '.item.id // empty' "$APP_UPLOAD_RESPONSE")"
  test_file_id="$(jq -r '.item.id // empty' "$TEST_UPLOAD_RESPONSE")"
  if [[ -n "$app_file_id" || -n "$test_file_id" ]]; then
    echo "Or use these file ids:"
    if [[ -n "$app_file_id" ]]; then
      echo "app: storage:$app_file_id"
    fi
    if [[ -n "$test_file_id" ]]; then
      echo "testApp: storage:$test_file_id"
    fi
  fi
fi
