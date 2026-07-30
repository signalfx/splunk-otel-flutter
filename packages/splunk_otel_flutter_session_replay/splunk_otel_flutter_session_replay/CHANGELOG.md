## Unreleased

* Sync version bump to align with `splunk_otel_flutter`, which adds the manual `customTracking.trackError()` API. Native Splunk RUM SDK pins stay aligned with `splunk_otel_flutter` (Android 2.3.2, iOS pin to be bumped alongside `splunk_otel_flutter` when the release exposing the explicit-stacktrace `trackError` API is published).
* Pinned the platform-interface dependencies to the matching minor line (`>=1.1.0 <1.2.0`) so the shared Pigeon codec stays version-aligned across packages.

## 1.1.0

* Aligned the native Splunk RUM SDK pins with `splunk_otel_flutter` (Android 2.3.2, iOS 2.3.1). This fixes a native dependency conflict on iOS where `splunk_otel_flutter` and `splunk_otel_flutter_session_replay` pinned different exact versions of `splunk-otel-ios`.

## 1.0.3

* Sync version bump to align with `splunk_otel_flutter` 1.0.3.

## 1.0.2

* Bumped native iOS Splunk RUM SDK to 2.2.3, which fixes an App Store validation failure (`Validation failed (409) CFBundleIdentifier Collision`) that prevented users from uploading their apps.

## 1.0.1

* Fix for Android build.

## 1.0.0

**First stable release.**

* Initial release of the session replay module for Splunk OpenTelemetry Flutter
* Android and iOS platform support
* Enabled via `SessionReplayModuleConfiguration` from `splunk_otel_flutter`, with a configurable sampling rate
