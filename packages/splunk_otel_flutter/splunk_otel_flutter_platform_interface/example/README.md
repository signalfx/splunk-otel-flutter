# splunk_otel_flutter_platform_interface Example

This example demonstrates how to use the `splunk_otel_flutter_platform_interface` package.

## Overview

The example shows:

- Creating and configuring the Splunk OpenTelemetry agent
- Setting up endpoint configuration for RUM
- Enabling various instrumentation modules (crashes, navigation, network, etc.)
- Managing global attributes
- Tracking custom events
- Tracking screen navigation
- Using workflows for tracking multi-step processes

## Usage

This is a platform interface package. In a real application, you would typically use the
`splunk_otel_flutter` package which implements this interface for Android and iOS platforms.

## Running the Example

```bash
cd example
flutter pub get
dart main.dart
```

Note: This example will not actually send data to Splunk without a platform-specific implementation.
For a complete working example, see the `splunk_otel_flutter` package.

## Key Concepts

### Agent Configuration

The agent must be configured with:
- **Endpoint configuration**: Where to send telemetry data (RUM realm/token or custom endpoints)
- **App name**: Your application name
- **Deployment environment**: e.g., 'production', 'staging', 'dev'
- **Optional settings**: Debug logging, global attributes, user tracking, session sampling

### Module Configurations

Modules enable specific instrumentation features:
- `CrashReportsModuleConfiguration`: Capture crashes and exceptions
- `NavigationModuleConfiguration`: Track screen navigation
- `SlowRenderingModuleConfiguration`: Detect slow/frozen frames
- `InteractionsModuleConfiguration`: Track user interactions
- `NetworkMonitorModuleConfiguration`: Track network connectivity changes
- Platform-specific modules (ANR detection, HTTP instrumentation, etc.)

### Custom Tracking

You can add custom instrumentation:
- **Custom events**: Track specific user actions or app events
- **Global attributes**: Add attributes to all telemetry data
- **Workflows**: Track multi-step user flows with start/end markers
- **Navigation**: Manually track screen changes

## See Also

- [splunk_otel_flutter](../../splunk_otel_flutter) - The main package with platform implementations
- [Splunk RUM Documentation](https://docs.splunk.com/Observability/rum/intro-to-rum.html)
