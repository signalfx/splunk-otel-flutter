#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-emulator-5554}"
REALM="${REALM:-mon0}"
ANR_BLOCK_SECONDS="${ANR_BLOCK_SECONDS:-15}"
TELEMETRY_SETTLE_SECONDS="${TELEMETRY_SETTLE_SECONDS:-180}"
LOGCAT_OUTPUT="$APP_DIR/build/anr_test.log"

if [[ -z "${RUM_ACCESS_TOKEN:-}" ]]; then
  echo "RUM_ACCESS_TOKEN is required."
  echo "Example: REALM=mon0 RUM_ACCESS_TOKEN=<token> $0"
  exit 1
fi

cd "$APP_DIR"

echo "Clearing logcat..."
adb -s "$DEVICE_ID" logcat -c

echo "Running ANR integration test on $DEVICE_ID..."
echo "ANR block seconds: $ANR_BLOCK_SECONDS"
echo "Telemetry settle seconds: $TELEMETRY_SETTLE_SECONDS"

set +e
flutter test integration_test/anr_test.dart -d "$DEVICE_ID" \
  --dart-define=REALM="$REALM" \
  --dart-define=RUM_ACCESS_TOKEN="$RUM_ACCESS_TOKEN" \
  --dart-define=ANR_BLOCK_SECONDS="$ANR_BLOCK_SECONDS" \
  --dart-define=TELEMETRY_SETTLE_SECONDS="$TELEMETRY_SETTLE_SECONDS"
test_status=$?
set -e

mkdir -p "$APP_DIR/build"
adb -s "$DEVICE_ID" logcat -d > "$LOGCAT_OUTPUT"
echo "Saved logcat to $LOGCAT_OUTPUT"
echo "ANR-related log lines:"
grep -iE "ANR|Application Not Responding|AnrIntegration|device.anr|SplunkRum|writeOtelSpanData|UploadOtelSpanDataJob|LoggerSpanExporter|Session replay|Core status|anr.enabled" "$LOGCAT_OUTPUT" || true

if ! grep -qiE "ANR|device.anr|Application Not Responding|AnrIntegration" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find clear ANR evidence in logcat."
fi

if ! grep -q "UploadOtelSpanDataJob: startUpload() onSuccess: .*code=200" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find a successful OTEL span upload with code=200 in logcat."
fi

if [[ "$test_status" -ne 0 ]]; then
  echo "ANR test failed with status $test_status."
  exit "$test_status"
fi

echo "Done. Check Olly for the ANR report."
