#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-emulator-5554}"
REALM="${REALM:-mon0}"
STARTUP_SETTLE_SECONDS="${STARTUP_SETTLE_SECONDS:-20}"
TELEMETRY_SETTLE_SECONDS="${TELEMETRY_SETTLE_SECONDS:-90}"
APP_ERROR_COUNT="${APP_ERROR_COUNT:-3}"
PACKAGE_NAME="com.splunk.rum.flutter.root.exampleapp.root_example_app"
MAIN_ACTIVITY="$PACKAGE_NAME/.MainActivity"
APP_ERRORS_ACTION="$PACKAGE_NAME.APP_ERRORS"
LOGCAT_OUTPUT="$APP_DIR/build/app_errors.log"

if [[ -z "${RUM_ACCESS_TOKEN:-}" ]]; then
  echo "RUM_ACCESS_TOKEN is required."
  echo "Example: REALM=mon0 RUM_ACCESS_TOKEN=<token> DEVICE_ID=$DEVICE_ID $0"
  exit 1
fi

cd "$APP_DIR"

echo "Building debug APK with realm $REALM..."
flutter build apk --debug \
  --dart-define=REALM="$REALM" \
  --dart-define=RUM_ACCESS_TOKEN="$RUM_ACCESS_TOKEN"

echo "Installing APK on $DEVICE_ID..."
adb -s "$DEVICE_ID" install -r build/app/outputs/flutter-apk/app-debug.apk

echo "Clearing logcat..."
adb -s "$DEVICE_ID" logcat -c

echo "Starting from a clean app process..."
adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME"

echo "Launching app normally..."
adb -s "$DEVICE_ID" shell am start -n "$MAIN_ACTIVITY"
echo "Waiting $STARTUP_SETTLE_SECONDS seconds for SDK initialization..."
sleep "$STARTUP_SETTLE_SECONDS"

echo "Triggering $APP_ERROR_COUNT handled app errors..."
adb -s "$DEVICE_ID" shell am start \
  -n "$MAIN_ACTIVITY" \
  -a "$APP_ERRORS_ACTION" \
  --ei app_error_count "$APP_ERROR_COUNT"

echo "Keeping app open for $TELEMETRY_SETTLE_SECONDS seconds for Olly upload..."
sleep "$TELEMETRY_SETTLE_SECONDS"

mkdir -p "$APP_DIR/build"
adb -s "$DEVICE_ID" logcat -d > "$LOGCAT_OUTPUT"
echo "Saved logcat to $LOGCAT_OUTPUT"
echo "App-error related log lines:"
grep -iE "AppErrorDiagnostics|Intentional handled app error|name=IllegalStateException|component=error|error=true|exception.type|exception.message|writeOtelSpanData|UploadOtelSpanDataJob|LoggerSpanExporter" "$LOGCAT_OUTPUT" || true

if ! grep -qiE "name=IllegalStateException|exception.type=.*IllegalStateException|component=error" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find handled app-error spans in logcat."
fi

if ! grep -q "UploadOtelSpanDataJob: startUpload() onSuccess: .*code=200" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find a successful OTEL span upload with code=200 in logcat."
fi

echo "Done. Check Olly RUM Errors for handled app errors."
