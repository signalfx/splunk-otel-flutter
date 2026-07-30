## Unreleased

* Added a manual `customTracking.trackError()` API for reporting caught Dart errors as `component=error` RUM spans, with the supplied stacktrace preserved verbatim as `exception.stacktrace`. Includes a new `ErrorSource` enum, optional attributes, and a `handled` flag (reported as `exception.escaped`). The call never throws and always completes. Android is supported via the native SDK 2.3.2; iOS support activates once the native iOS SDK release exposing the explicit-stacktrace `trackError` API is published and pinned.

## 1.1.0

* Added automatic navigation instrumentation: a `SplunkNavigatorObserver` (with optional view-name, tracking-filter, and attribute predicates) that reports screen changes from Navigator 1.0/2.0, `go_router`, and `auto_route`, plus an optional `attributes` argument on `Navigation.track`.
* Bumped the native Android Splunk RUM SDK to 2.3.2 (the iOS native SDK remains pinned at 2.3.1).

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
