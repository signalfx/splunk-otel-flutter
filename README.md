# Splunk OpenTelemetry Instrumentation for Flutter

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![pub.dev: splunk_otel_flutter](https://img.shields.io/pub/v/splunk_otel_flutter.svg?label=splunk_otel_flutter)](https://pub.dev/packages/splunk_otel_flutter)
[![pub.dev: splunk_otel_flutter_session_replay](https://img.shields.io/pub/v/splunk_otel_flutter_session_replay.svg?label=splunk_otel_flutter_session_replay)](https://pub.dev/packages/splunk_otel_flutter_session_replay)

The Splunk Distribution of OpenTelemetry for Flutter instruments Flutter
applications for Real User Monitoring (RUM) and sends telemetry to
[Splunk Observability Cloud](https://www.splunk.com/en_us/products/observability.html).

It captures:

- App lifecycle, startup, and performance metrics
- Network request instrumentation
- Navigation and user interactions
- Crashes, ANRs, and slow rendering
- Custom events and workflows
- (Optional) session replay recordings

Supported platforms: **iOS 15.0+** and **Android API 24+**.

## Packages

This repository is a Dart 3 / Melos workspace containing the public SDK and
its federated platform interfaces.

| Package | Description |
| --- | --- |
| [`splunk_otel_flutter`](./packages/splunk_otel_flutter/splunk_otel_flutter#readme) | Core RUM SDK. Start here — installation, configuration, and the public API (`SplunkRum.instance`). |
| [`splunk_otel_flutter_session_replay`](./packages/splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay#readme) | Optional session replay add-on. Records UI for visual session playback in Splunk Observability Cloud. |
| [`splunk_otel_flutter_platform_interface`](./packages/splunk_otel_flutter/splunk_otel_flutter_platform_interface) | Pigeon-generated Dart ↔ native contract for the core SDK. Internal use. |
| [`splunk_otel_flutter_session_replay_platform_interface`](./packages/splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay_platform_interface) | Pigeon-generated Dart ↔ native contract for session replay. Internal use. |

If you are integrating the SDK in your app, you only need the first one (and
optionally session replay).

## Quick start

Add the core package to your app's `pubspec.yaml`:

```yaml
dependencies:
  splunk_otel_flutter: ^1.0.1
  # Optional: enable visual session replay
  splunk_otel_flutter_session_replay: ^1.0.0
```

Initialize the SDK before `runApp`:

```dart
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SplunkRum.instance.install(
    agentConfiguration: AgentConfiguration(
      endpoint: EndpointConfiguration.forRum(
        realm: 'us0',
        rumAccessToken: 'YOUR_RUM_ACCESS_TOKEN',
      ),
      appName: 'MyApp',
      deploymentEnvironment: 'production',
    ),
  );

  runApp(const MyApp());
}
```

For platform setup (iOS Swift Package Manager, Android desugaring and
`minSdkVersion`), module configuration, global attributes, custom events,
and session replay usage, see the package READMEs linked above.

## Documentation

- [Install the Splunk RUM Flutter Agent](https://help.splunk.com/en/splunk-observability-cloud/manage-data/available-data-sources/supported-integrations-in-splunk-observability-cloud/rum-instrumentation/instrument-mobile-and-web-applications-for-splunk-real-user-monitoring-rum/instrument-flutter-applications-for-splunk-rum/install-the-splunk-rum-flutter-agent)
- [Record Flutter Sessions](https://help.splunk.com/en/splunk-observability-cloud/monitor-end-user-experience/real-user-monitoring/replay-user-sessions/record-flutter-sessions)
- [Troubleshoot Flutter Instrumentation](https://help.splunk.com/en/splunk-observability-cloud/manage-data/available-data-sources/supported-integrations-in-splunk-observability-cloud/rum-instrumentation/instrument-mobile-and-web-applications-for-splunk-real-user-monitoring-rum/instrument-flutter-applications-for-splunk-rum/troubleshoot-flutter-instrumentation)

## Examples

- [`packages/splunk_otel_flutter/splunk_otel_flutter/example`](./packages/splunk_otel_flutter/splunk_otel_flutter/example) — minimal example app for the core SDK.
- [`packages/splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay/example`](./packages/splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay/example) — minimal session replay example.
- [`splunk_otel_flutter_root_example_app`](./splunk_otel_flutter_root_example_app) — full end-to-end demo app exercising both packages.

## Contributing

Contributions are welcome. See:

- [SETUP.md](./SETUP.md) — local development environment and Git hooks
- [CONTRIBUTING.md](./CONTRIBUTING.md) — contribution workflow and conventions
- [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)
- [SECURITY.md](./SECURITY.md) — reporting vulnerabilities
- [RELEASE.md](./RELEASE.md) — maintainer release process

## Support

- [GitHub Issues](https://github.com/signalfx/splunk-otel-flutter/issues)
- [Splunk Observability Documentation](https://help.splunk.com/en/splunk-observability-cloud/get-started)

## License

Copyright 2026 Splunk Inc.

Licensed under the [Apache License, Version 2.0](./LICENSE).

> SignalFx was acquired by Splunk in October 2019. See [Splunk SignalFx](https://www.splunk.com/en_us/investor-relations/acquisitions/signalfx.html) for more information.
