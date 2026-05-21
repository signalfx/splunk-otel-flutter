# Sauce Appium telemetry tests

These Appium jobs run outside the app process so they can create OS-level
conditions that are difficult to drive from an in-app Flutter integration test.

Required environment variables:

```bash
SAUCE_USERNAME=<your Sauce username>
SAUCE_ACCESS_KEY=<your Sauce access key>
SAUCE_APP_NAME=smart-cinema.apk
```

Optional environment variables:

```bash
SAUCE_REGION=us-west-1
SAUCE_DEVICE_NAME="Google Pixel 7 Pro GoogleAPI Emulator"
SAUCE_PLATFORM_VERSION=15.0
STARTUP_SETTLE_SECONDS=30
HOT_START_BACKGROUND_SECONDS=10
HOT_START_SETTLE_SECONDS=20
CRASH_SETTLE_SECONDS=20
TELEMETRY_SETTLE_SECONDS=180
```

Run the bad-email crash test:

```bash
../tool/run_sauce_bad_email_crash_appium.sh
```

Run the hot-startup test:

```bash
../tool/run_sauce_hot_startup_appium.sh
```
