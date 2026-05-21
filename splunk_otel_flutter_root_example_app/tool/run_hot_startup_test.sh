#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-emulator-5554}"
REALM="${REALM:-mon0}"
STARTUP_SETTLE_SECONDS="${STARTUP_SETTLE_SECONDS:-30}"
HOT_START_BACKGROUND_SECONDS="${HOT_START_BACKGROUND_SECONDS:-10}"
HOT_START_SETTLE_SECONDS="${HOT_START_SETTLE_SECONDS:-20}"
TELEMETRY_SETTLE_SECONDS="${TELEMETRY_SETTLE_SECONDS:-180}"
PACKAGE_NAME="com.splunk.rum.flutter.root.exampleapp.root_example_app"
MAIN_ACTIVITY="$PACKAGE_NAME/.MainActivity"
LOGCAT_OUTPUT="$APP_DIR/build/hot_startup.log"

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

echo "Launching app for cold-start initialization..."
adb -s "$DEVICE_ID" shell am start -n "$MAIN_ACTIVITY"
echo "Waiting $STARTUP_SETTLE_SECONDS seconds for SDK initialization..."
sleep "$STARTUP_SETTLE_SECONDS"

echo "Sending app to background..."
adb -s "$DEVICE_ID" shell input keyevent KEYCODE_HOME
echo "Waiting $HOT_START_BACKGROUND_SECONDS seconds in background..."
sleep "$HOT_START_BACKGROUND_SECONDS"

echo "Bringing app back to foreground to create a hot start..."
adb -s "$DEVICE_ID" shell am start -n "$MAIN_ACTIVITY"
echo "Waiting $HOT_START_SETTLE_SECONDS seconds for hot-start telemetry..."
sleep "$HOT_START_SETTLE_SECONDS"

echo "Keeping app open for $TELEMETRY_SETTLE_SECONDS seconds for Olly upload..."
sleep "$TELEMETRY_SETTLE_SECONDS"

mkdir -p "$APP_DIR/build"
adb -s "$DEVICE_ID" logcat -d > "$LOGCAT_OUTPUT"
echo "Saved logcat to $LOGCAT_OUTPUT"
echo "Hot-start related log lines:"
grep -iE "HotStartup|HotStartupDiagnostics|Synthetic AppStart|name=AppStart|appstart|start.type|hot_startup.duration_ms|startup.duration_ms|hot|UploadOtelSpanDataJob|LoggerSpanExporter|SplunkRum|startup|already reported" "$LOGCAT_OUTPUT" || true

if ! grep -qiE "name=HotStartup|hot_startup.duration_ms|start.type=hot" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find the custom HotStartup span in logcat."
fi

if ! grep -qiE "name=AppStart.*start.type=hot|start.type=hot.*name=AppStart|Synthetic AppStart hot span ended" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find the synthetic AppStart hot span in logcat."
fi

if ! grep -q "UploadOtelSpanDataJob: startUpload() onSuccess: .*code=200" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find a successful OTEL span upload with code=200 in logcat."
fi

echo "Done. Check Olly for component=appstart and start.type=hot."
