#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-emulator-5554}"
REALM="${REALM:-mon0}"
STARTUP_SETTLE_SECONDS="${STARTUP_SETTLE_SECONDS:-30}"
CRASH_SETTLE_SECONDS="${CRASH_SETTLE_SECONDS:-20}"
TELEMETRY_SETTLE_SECONDS="${TELEMETRY_SETTLE_SECONDS:-180}"
PACKAGE_NAME="com.splunk.rum.flutter.root.exampleapp.root_example_app"
MAIN_ACTIVITY="$PACKAGE_NAME/.MainActivity"
BAD_EMAIL_CRASH_ACTION="$PACKAGE_NAME.BAD_EMAIL_CRASH"
LOGCAT_OUTPUT="$APP_DIR/build/bad_email_crash_relaunch.log"

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

echo "Starting from a clean app process..."
adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME"

echo "Launching app normally..."
adb -s "$DEVICE_ID" shell am start -n "$MAIN_ACTIVITY"
echo "Waiting $STARTUP_SETTLE_SECONDS seconds for SDK initialization..."
sleep "$STARTUP_SETTLE_SECONDS"

echo "Triggering bad-email native crash through Android intent..."
set +e
adb -s "$DEVICE_ID" shell am start -n "$MAIN_ACTIVITY" -a "$BAD_EMAIL_CRASH_ACTION"
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
grep -iE "Intentional native crash from login screen invalid email|FATAL EXCEPTION|CrashIntegration|CrashReporter|device.crash|SplunkRum|CrashUploadDelay|writeOtelSpanData|UploadOtelSpanDataJob|forceFlush|export" "$LOGCAT_OUTPUT" || true

if ! grep -q "Intentional native crash from login screen invalid email" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find the bad-email native crash message in logcat."
fi

echo "Done. Check Olly for the bad-email crash report."
