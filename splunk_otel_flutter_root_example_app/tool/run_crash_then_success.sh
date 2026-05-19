#!/usr/bin/env bash
set -u

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-emulator-5554}"
REALM="${REALM:-mon0}"
TELEMETRY_SETTLE_SECONDS="${TELEMETRY_SETTLE_SECONDS:-30}"

if [[ -z "${RUM_ACCESS_TOKEN:-}" ]]; then
  echo "RUM_ACCESS_TOKEN is required."
  echo "Example: RUM_ACCESS_TOKEN=<token> $0"
  exit 1
fi

cd "$APP_DIR"

crash_log="$(mktemp)"
trap 'rm -f "$crash_log"' EXIT

echo "Running crash-trigger test on $DEVICE_ID..."
set +e
flutter test integration_test/login_screen_crash.dart -d "$DEVICE_ID" \
  --dart-define=REALM="$REALM" \
  --dart-define=RUM_ACCESS_TOKEN="$RUM_ACCESS_TOKEN" 2>&1 | tee "$crash_log"
crash_status=${PIPESTATUS[0]}
set -e

if [[ "$crash_status" -eq 0 ]]; then
  echo "Expected the app to exit during the crash test, but the test completed successfully."
  exit 1
fi

if ! grep -q "did not complete" "$crash_log"; then
  echo "Crash test failed, but it did not look like the expected app-exit signal."
  exit "$crash_status"
fi

echo "Crash-trigger test ended with status $crash_status, continuing because app exit is expected."
sleep 2

echo "Running successful login test on $DEVICE_ID..."
flutter test integration_test/login_success_test.dart -d "$DEVICE_ID" \
  --dart-define=REALM="$REALM" \
  --dart-define=RUM_ACCESS_TOKEN="$RUM_ACCESS_TOKEN" \
  --dart-define=TELEMETRY_SETTLE_SECONDS="$TELEMETRY_SETTLE_SECONDS"
