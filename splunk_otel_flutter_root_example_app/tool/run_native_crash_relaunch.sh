#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-emulator-5554}"
REALM="${REALM:-mon0}"
STARTUP_SETTLE_SECONDS="${STARTUP_SETTLE_SECONDS:-10}"
CRASH_SETTLE_SECONDS="${CRASH_SETTLE_SECONDS:-15}"
TELEMETRY_SETTLE_SECONDS="${TELEMETRY_SETTLE_SECONDS:-120}"
PACKAGE_NAME="com.splunk.rum.flutter.root.exampleapp.root_example_app"
MAIN_ACTIVITY="$PACKAGE_NAME/.MainActivity"
CRASH_ACTION="$PACKAGE_NAME.INTENTIONAL_CRASH"
LOGCAT_OUTPUT="$APP_DIR/build/native_crash_relaunch.log"

if [[ -z "${RUM_ACCESS_TOKEN:-}" ]]; then
  echo "RUM_ACCESS_TOKEN is required."
  echo "Example: REALM=mon0 RUM_ACCESS_TOKEN=<token> $0"
  exit 1
fi

cd "$APP_DIR"

echo "Building debug APK with realm $REALM..."
flutter build apk --debug \
  --dart-define=REALM="$REALM" \
  --dart-define=RUM_ACCESS_TOKEN="$RUM_ACCESS_TOKEN"

echo "Installing APK on $DEVICE_ID without clearing app data..."
adb -s "$DEVICE_ID" install -r build/app/outputs/flutter-apk/app-debug.apk

echo "Clearing logcat..."
adb -s "$DEVICE_ID" logcat -c

echo "Launching app normally..."
adb -s "$DEVICE_ID" shell am start -n "$MAIN_ACTIVITY"
echo "Waiting $STARTUP_SETTLE_SECONDS seconds for SDK initialization..."
sleep "$STARTUP_SETTLE_SECONDS"

echo "Triggering native crash through Android intent..."
set +e
adb -s "$DEVICE_ID" shell am start -n "$MAIN_ACTIVITY" -a "$CRASH_ACTION"
set -e

echo "Waiting $CRASH_SETTLE_SECONDS seconds for crash flush and process shutdown..."
sleep "$CRASH_SETTLE_SECONDS"

echo "Relaunching the same installed app so stored crash can upload..."
adb -s "$DEVICE_ID" shell am start -n "$MAIN_ACTIVITY"
echo "Keeping app open for $TELEMETRY_SETTLE_SECONDS seconds..."
sleep "$TELEMETRY_SETTLE_SECONDS"

mkdir -p "$APP_DIR/build"
adb -s "$DEVICE_ID" logcat -d > "$LOGCAT_OUTPUT"
echo "Saved logcat to $LOGCAT_OUTPUT"
echo "Crash-related log lines:"
grep -iE "Intentional native crash|FATAL EXCEPTION|CrashIntegration|CrashReporter|device.crash|SplunkRum|CrashUploadDelay|writeOtelSpanData|UploadOtelSpanDataJob|forceFlush|export" "$LOGCAT_OUTPUT" || true

echo "Done. Check Olly for the crash report."
