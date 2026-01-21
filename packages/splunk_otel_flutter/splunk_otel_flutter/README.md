# splunk_otel_flutter

> ⚠️ **Alpha Release**: This package is currently in alpha. APIs may change, and it is not recommended for production use.

Splunk OpenTelemetry instrumentation for Flutter applications. This package enables real-time monitoring, tracing, and observability for your Flutter apps using Splunk Observability Cloud.

## Features

- 🔍 Distributed tracing
- 📊 Performance monitoring (slow rendering, ANR detection)
- 🐛 Crash reporting
- 🌐 Network request instrumentation
- 📱 Navigation tracking
- 🔧 Custom event tracking
- 📝 Global attributes management
- 👤 User tracking modes

## Setup

### Android

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

2. Save and sync your project.

### iOS

#### Enable Swift Package Manager

Enable Swift Package Manager for your Flutter project:

```bash
flutter config --enable-swift-package-manager
```

For more information, see the [official Flutter documentation on Swift Package Manager](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers).

## Usage

```dart
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SplunkRum.instance.install(
    agentConfiguration: AgentConfiguration(
      endpointConfiguration: EndpointConfiguration.forRum(
        realm: 'your-realm',
        rumAccessToken: 'your-rum-access-token',
      ),
      appName: 'Your App name',
      deploymentEnvironment: 'dev',
    ),
    moduleConfigurations: [
      NavigationModuleConfiguration(isEnabled: true),
      SlowRenderingModuleConfiguration(isEnabled: true),
      AnrModuleConfiguration(isEnabled: true),
      CrashReportsModuleConfiguration(isEnabled: true),
    ],
  );

  runApp(MyApp());
}
```

## Requirements

- Flutter SDK: `>=3.32.0`
- Dart SDK: `>=3.8.0 <4.0.0`
- iOS: 15.0+
- Android: API level 24+

## Documentation

For detailed documentation, visit the [Flutter instrumentation guide](https://help.splunk.com/en/appdynamics-saas/end-user-monitoring/25.5.0/end-user-monitoring/mobile-real-user-monitoring/instrument-flutter-applications).
