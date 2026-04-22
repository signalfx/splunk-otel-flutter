# Splunk Session Replay for Flutter

Session replay module for the [Splunk Distribution of OpenTelemetry for Flutter](https://github.com/signalfx/splunk-otel-flutter).

This package captures your application's UI so that sessions can be reviewed as visual replays in Splunk Observability Cloud. It is an add-on to the core Splunk RUM SDK (`splunk_otel_flutter`) and cannot be used on its own.

## Requirements

- Flutter SDK: `>=3.32.0`
- Dart SDK: `>=3.8.0 <4.0.0`
- iOS: 15.0+
- Android: API level 24+ (minSdkVersion 24)
- `splunk_otel_flutter` already installed and configured in your app

## Installation

Add both packages to your `pubspec.yaml`:

```yaml
dependencies:
  splunk_otel_flutter: ^1.0.0
  splunk_otel_flutter_session_replay: ^1.0.0
```

Then run:

```bash
flutter pub get
```

Platform setup (Swift Package Manager on iOS, desugaring and `minSdkVersion` on Android) is identical to the core SDK. See the [`splunk_otel_flutter` README](https://github.com/signalfx/splunk-otel-flutter/tree/main/packages/splunk_otel_flutter/splunk_otel_flutter#readme) for full platform setup instructions.

## Usage

### 1. Enable the module when installing the SDK

Session replay is enabled by passing `SessionReplayModuleConfiguration` (exported from `splunk_otel_flutter`) to `SplunkRum.instance.install()`:

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
    moduleConfigurations: [
      SessionReplayModuleConfiguration(
        samplingRate: 0.2, // record 20% of sessions (default)
      ),
    ],
  );

  runApp(const MyApp());
}
```

`samplingRate` accepts a value in `[0.0, 1.0]`. Values outside that range are clamped (a debug message is logged). The default is `0.2`.

### 2. Control recording at runtime

Once the SDK is installed, use `SplunkSessionReplay.instance` to start, stop, and inspect recording:

```dart
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

await SplunkSessionReplay.instance.start();

final status = await SplunkSessionReplay.instance.getStatus();
// SessionReplayStatus.isRecording, notStarted, stopped, belowMinSdkVersion,
// storageLimitReached, internalError, disabledBySampling

await SplunkSessionReplay.instance.stop();
```

### 3. Mask sensitive content

Use a `RecordingMask` to hide or cover specific regions of the UI. Masks are defined as a list of `MaskElement` entries, each combining a `Rect` (in logical pixels) with a `MaskType`:

```dart
import 'dart:ui';
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

final mask = RecordingMask(
  elements: [
    MaskElement(
      rect: const Rect.fromLTWH(0, 0, 300, 60),
      type: MaskType.covering, // overlay with a solid color
    ),
    MaskElement(
      rect: const Rect.fromLTWH(0, 200, 300, 40),
      type: MaskType.erasing, // remove content from the replay
    ),
  ],
);

await SplunkSessionReplay.instance.setRecordingMask(mask: mask);

// Clear the mask later:
await SplunkSessionReplay.instance.setRecordingMask(mask: null);

// Read back the current mask:
final current = await SplunkSessionReplay.instance.getRecordingMask();
```

## Public API at a glance

- `SplunkSessionReplay.instance` — singleton with `start()`, `stop()`, `getStatus()`, `getRecordingMask()`, `setRecordingMask()`.
- `SessionReplayStatus` — enum describing the current recording state.
- `RecordingMask`, `MaskElement`, `MaskType` — masking model used to hide sensitive UI.
- `SessionReplayModuleConfiguration` — exported from `splunk_otel_flutter`; used to enable the module and set the sampling rate.

## Support

- [GitHub Issues](https://github.com/signalfx/splunk-otel-flutter/issues)
- [Splunk Observability Documentation](https://help.splunk.com/en/splunk-observability-cloud/get-started)
- [Flutter Instrumentation Guide](https://help.splunk.com/en/appdynamics-saas/end-user-monitoring/25.5.0/end-user-monitoring/mobile-real-user-monitoring/instrument-flutter-applications)

## License

Copyright 2026 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
