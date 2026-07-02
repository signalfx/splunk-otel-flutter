## Unreleased

* Added automatic navigation instrumentation: a `SplunkNavigatorObserver` (with optional view-name, tracking-filter, and attribute predicates) that reports screen changes from Navigator 1.0/2.0, `go_router`, and `auto_route`, plus an optional `attributes` argument on `Navigation.track`. Requires the native Splunk RUM SDKs at 2.3.1.

## 1.0.3

* Added support for configuring captured network request headers on iOS via `NetworkMonitorModuleConfiguration`.

## 1.0.2

* Bumped native iOS Splunk RUM SDK to 2.2.3, which fixes an App Store validation failure (`Validation failed (409) CFBundleIdentifier Collision`) that prevented users from uploading their apps.

## 1.0.1

* Fix for Android build.

## 1.0.0

**First stable release.**

* Session replay support via `SessionReplayModuleConfiguration` (requires the `splunk_otel_flutter_session_replay` package)
* Public API aligned with the native Android/iOS SDKs (parameter renames, default value changes)
* Bumped native Splunk RUM SDKs to 2.2.2


## 1.0.0-alpha.1

* Core Flutter plugin implementation for Splunk OpenTelemetry
* Android and iOS platform support
* Basic telemetry collection and export functionality
* Configuration management for RUM (Real User Monitoring)
* Session tracking and management
* Custom attributes support


## 1.0.0-dev.1

* Initial development release
