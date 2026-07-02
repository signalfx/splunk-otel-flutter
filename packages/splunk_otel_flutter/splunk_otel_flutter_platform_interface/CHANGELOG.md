## Unreleased

* Extended the `navigationTrack` Pigeon message and platform interface with an optional `attributes` argument to support automatic navigation instrumentation.

## 1.0.3

* Extended `NetworkMonitorModuleConfiguration` and Pigeon messages to bridge captured network request headers to iOS.

## 1.0.2

* Version bump to align with `splunk_otel_flutter` 1.0.2, which fixes an App Store validation failure (`Validation failed (409) CFBundleIdentifier Collision`) that prevented users from uploading their apps.

## 1.0.1

* Fix for Android build.

## 1.0.0

**First stable release.**

* Added `SessionReplayModuleConfiguration` to support the session replay module
* Pigeon messages and data models synced with the native Android/iOS SDKs (parameter renames, default value changes)

## 1.0.0-alpha.1

* Platform interface for Splunk Flutter SDK
* Pigeon-based communication bridge between Flutter and native platforms
* Core data models and configuration interfaces
* Abstract platform implementation contracts

## 1.0.0-dev.1

* Initial development release
