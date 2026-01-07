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

## Usage

```dart
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SplunkOtelFlutter.instance.install(
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
- Android: API level 21+

