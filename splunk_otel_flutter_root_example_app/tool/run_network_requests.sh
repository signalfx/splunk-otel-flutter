#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-emulator-5554}"
REALM="${REALM:-mon0}"
STARTUP_SETTLE_SECONDS="${STARTUP_SETTLE_SECONDS:-20}"
TELEMETRY_SETTLE_SECONDS="${TELEMETRY_SETTLE_SECONDS:-180}"
NETWORK_SUCCESS_URL="${NETWORK_SUCCESS_URL:-https://example.com/}"
NETWORK_HTTP_ERROR_URL="${NETWORK_HTTP_ERROR_URL:-https://httpbin.org/status/500}"
NETWORK_FAILURE_URL="${NETWORK_FAILURE_URL:-https://127.0.0.1:65534/}"
PACKAGE_NAME="com.splunk.rum.flutter.root.exampleapp.root_example_app"
MAIN_ACTIVITY="$PACKAGE_NAME/.MainActivity"
NETWORK_REQUESTS_ACTION="$PACKAGE_NAME.NETWORK_REQUESTS"
LOGCAT_OUTPUT="$APP_DIR/build/network_requests.log"

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

echo "Triggering native OkHttp network requests through Android intent..."
adb -s "$DEVICE_ID" shell am start \
  -n "$MAIN_ACTIVITY" \
  -a "$NETWORK_REQUESTS_ACTION" \
  --es network_success_url "$NETWORK_SUCCESS_URL" \
  --es network_http_error_url "$NETWORK_HTTP_ERROR_URL" \
  --es network_failure_url "$NETWORK_FAILURE_URL"

echo "Keeping app open for $TELEMETRY_SETTLE_SECONDS seconds..."
sleep "$TELEMETRY_SETTLE_SECONDS"

mkdir -p "$APP_DIR/build"
adb -s "$DEVICE_ID" logcat -d > "$LOGCAT_OUTPUT"
echo "Saved logcat to $LOGCAT_OUTPUT"
echo "Network-related log lines:"
grep -iE "NetworkDiagnostics|OkHttp|component=http|httpbin|example.com|127.0.0.1|http.url|url.full|http.request.method|http.response.status_code|http.status_code|error=true|writeOtelSpanData|UploadOtelSpanDataJob|LoggerSpanExporter|Network request|Request finished|Request failed" "$LOGCAT_OUTPUT" || true

if ! grep -q "Starting network diagnostics from Android intent" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find the Android intent network trigger in logcat."
fi

if ! grep -q "component=http" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find Splunk OkHttp network spans with component=http in logcat."
fi

if ! grep -q "UploadOtelSpanDataJob: startUpload() onSuccess: .*code=200" "$LOGCAT_OUTPUT"; then
  echo "Warning: did not find a successful OTEL span upload with code=200 in logcat."
fi

echo "Done. Check Olly for network requests and network errors."
