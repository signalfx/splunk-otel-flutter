# Splunk Distribution of OpenTelemetry for Flutter

> [!IMPORTANT]
> Splunk Flutter instrumentation distribution is in alpha state and subject to the terms at https://www.splunk.com/en_us/legal/pre-release-agreement-for-hosted-services.html.

## Overview

The Splunk Distribution of OpenTelemetry for Flutter provides automatic instrumentation for Flutter applications running on Android and iOS devices. This library captures telemetry data including:

- Application lifecycle events
- Network request instrumentation
- User interactions and navigation tracking
- App startup and performance metrics
- Crash reporting
- Slow rendering detection (Android)
- ANR (Application Not Responding) detection (Android)
- Custom event and workflow tracking

## Requirements

- Flutter SDK: `>=3.32.0`
- Dart SDK: `>=3.8.0 <4.0.0`
- iOS: 15.0+
- Android: API level 24+ (minSdkVersion 24)

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  splunk_otel_flutter: ^1.0.0-dev.1
```

Then run:

```bash
flutter pub get
```

### Android Setup

#### Activate desugaring in your application

1. In your application module's `build.gradle` file, update the `compileOptions` and `dependencies` sections:

```groovy
android {
    compileOptions {
        // Flag to enable support for the new language APIs
        coreLibraryDesugaringEnabled true
        // Sets Java compatibility to Java 8
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        // If this setting is present, jvmTarget must be "1.8"
        jvmTarget = "1.8"
    }
}

dependencies {
    // For AGP 7.4+
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.3'
    // For AGP 7.3
    // coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:1.2.3'
    // For AGP 4.0 to 7.2
    // coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:1.1.9'
}
```

2. Ensure `minSdkVersion` is 24 or higher in your `build.gradle`:

```groovy
android {
    defaultConfig {
        minSdkVersion 24
    }
}
```

3. Save and sync your project.

### iOS Setup

#### Enable Swift Package Manager

Enable Swift Package Manager for your Flutter project:

```bash
flutter config --enable-swift-package-manager
```

For more information, see the [official Flutter documentation on Swift Package Manager](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers).

### iOS dSYM Upload (Crash Symbolication)

This package ships with a dSYM uploader script at `dsymUploader/upload-dsyms.sh`.
Add a Run Script build phase to your iOS `Runner` target and reference the script
from the plugin path (typically `ios/.symlinks/plugins/splunk_otel_flutter/dsymUploader/upload-dsyms.sh`).
See `dsymUploader/README.md` for full setup steps and troubleshooting.

## Quick Start

### 1. Initialize the SDK

Initialize the SDK in your app's `main()` function before running your app:

```dart
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SplunkRum.instance.install(
    agentConfiguration: AgentConfiguration(
      endpointConfiguration: EndpointConfiguration.forRum(
        realm: 'us0',
        rumAccessToken: 'YOUR_RUM_ACCESS_TOKEN',
      ),
      appName: 'MyApp',
      deploymentEnvironment: 'production',
    ),
  );

  runApp(MyApp());
}
```

## Configuration

### Module Configuration

Control which features are enabled by passing module configurations:

```dart
await SplunkRum.instance.install(
  agentConfiguration: AgentConfiguration(
    endpointConfiguration: EndpointConfiguration.forRum(
      realm: 'us0',
      rumAccessToken: 'YOUR_RUM_ACCESS_TOKEN',
    ),
    appName: 'MyApp',
    deploymentEnvironment: 'production',
  ),
  moduleConfigurations: [
    NavigationModuleConfiguration(isEnabled: true),
    SlowRenderingModuleConfiguration(
      isEnabled: true,
      interval: const Duration(seconds: 1),
    ),
    AnrModuleConfiguration(isEnabled: true),
    CrashReportsModuleConfiguration(isEnabled: true),
  ],
);
```

### Global Attributes

Add custom attributes to all telemetry:

```dart
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

// Set a single attribute
await SplunkRum.instance.globalAttributes.setString(
  key: 'user.id',
  value: '12345',
);

// Set multiple attributes
await SplunkRum.instance.globalAttributes.setAll(
  attributes: MutableAttributes(
    attributes: {
      'app.version': MutableAttributeString(value: '1.2.3'),
      'user.isPremium': MutableAttributeBool(value: true),
    },
  ),
);
```

### User Tracking

Control user session tracking:

```dart
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

// Set tracking mode
await SplunkRum.instance.user.preferences.setTrackingMode(
  userTrackingMode: UserTrackingMode.anonymousTracking,
);
```

### Custom Events

Track custom events:

```dart
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

// Track a simple event
await SplunkRum.instance.customTracking.trackCustomEvent(
  name: 'purchase_completed',
  attributes: MutableAttributes(
    attributes: {
      'product.id': MutableAttributeString(value: 'abc123'),
      'product.price': MutableAttributeDouble(value: 99.99),
    },
  ),
);

// Track a workflow with duration
final workflow = await SplunkRum.instance.customTracking.startWorkflow(
  name: 'checkout',
);
// ... perform checkout steps ...
await workflow.end();
```

### Navigation Tracking

Manually track screen navigation events:

```dart
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

// Track a screen view
await SplunkRum.instance.navigation.track(
  screenName: 'HomeScreen',
);
```

## Testing

For unit tests, you can mock the SDK by creating a test implementation or using dependency injection to provide a testable interface.

## Troubleshooting

### Common Issues

1. **Build errors on Android**
   - Ensure `minSdkVersion` is 24 or higher
   - Verify desugaring is properly configured
   - Clean build: `flutter clean && flutter pub get`

2. **Build errors on iOS**
   - Ensure you're using iOS 15.0+ as minimum deployment target
   - Verify Swift Package Manager is enabled: `flutter config --enable-swift-package-manager`
   - Clean build: `flutter clean && flutter pub get`

3. **SDK not initializing**
   - Ensure `WidgetsFlutterBinding.ensureInitialized()` is called before `install()`
   - Verify your RUM access token and realm are correct
   - Check that the SDK is installed before accessing `SplunkRum.instance`

## Contributing

Contributions are welcome! See the [Contributing Guide](https://github.com/signalfx/splunk-otel-flutter/blob/main/CONTRIBUTING.md).

## Support

- [GitHub Issues](https://github.com/signalfx/splunk-otel-flutter/issues)
- [Splunk Observability Documentation](https://help.splunk.com/en/splunk-observability-cloud/get-started)
- [Flutter Instrumentation Guide](https://help.splunk.com/en/appdynamics-saas/end-user-monitoring/25.5.0/end-user-monitoring/mobile-real-user-monitoring/instrument-flutter-applications)

## License

Copyright 2025 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.

> ℹ️ SignalFx was acquired by Splunk in October 2019. See [Splunk SignalFx](https://www.splunk.com/en_us/investor-relations/acquisitions/signalfx.html) for more information.
