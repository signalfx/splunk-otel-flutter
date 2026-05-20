## 1.0.2

* Bumped native iOS Splunk RUM SDK to 2.2.3, which fixes an App Store validation failure (`Validation failed (409) CFBundleIdentifier Collision`) that prevented users from uploading their apps.

## 1.0.1

* Fix for Android build.

## 1.0.0

**First stable release.**

* Initial release of the session replay module for Splunk OpenTelemetry Flutter
* Android and iOS platform support
* Enabled via `SessionReplayModuleConfiguration` from `splunk_otel_flutter`, with a configurable sampling rate
