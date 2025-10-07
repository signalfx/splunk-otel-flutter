import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/pigeon/messages.pigeon.dart',
    dartTestOut: 'test/pigeon/test_api.dart',
    dartPackageName: 'splunk_otel_flutter_platform_interface',
    kotlinOut:
        '../splunk_otel_flutter/android/src/main/kotlin/com/splunk/rum/flutter/GeneratedAndroidSplunkOtelFlutter.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.splunk.rum.flutter',
    ),
    swiftOut:
        '../splunk_otel_flutter/ios/splunk_otel_flutter/Sources/splunk_otel_flutter/SplunkOtelFlutterMessages.g.swift',
  ),
)

@HostApi(dartHostTestHandler: 'TestSplunkOtelFlutterHostApi')
abstract class SplunkOtelFlutterHostApi {
  @async
  void install(
      GeneratedAgentConfiguration agentConfiguration,
      GeneratedNavigationModuleConfiguration navigationModuleConfiguration,
      GeneratedSlowRenderingModuleConfiguration slowRenderingModuleConfiguration,
      );
}

class GeneratedSlowRenderingModuleConfiguration {
  final bool isEnabled;
  final int intervalMillis; // Changed from Duration to int (milliseconds)

  GeneratedSlowRenderingModuleConfiguration({
    required this.isEnabled,
    required this.intervalMillis,
  });
}

class GeneratedNavigationModuleConfiguration {
  final bool isEnabled;
  final bool isAutomatedTrackingEnabled;

  GeneratedNavigationModuleConfiguration({
    required this.isEnabled,
    required this.isAutomatedTrackingEnabled,
  });
}

class GeneratedAgentConfiguration {
  // Required properties (common to iOS and Android).
  final GeneratedEndpointConfiguration endpoint;
  final String appName;
  final String deploymentEnvironment;

  // Optional properties (common to iOS and Android).
  // On iOS, this typically defaults to CFBundleShortVersionString.
  final String? appVersion;

  // Enables or disables debug logging. Defaults to false.
  final bool enableDebugLogging;

  // Global attributes sent with all signals.
  // iOS: MutableAttributes; Android: Attributes. Represented here as a map.
  final Map<String?, Object?> globalAttributes;

  //TODO This type (SpanInterceptor) cannot be directly passed simply via Pigeon.

  // User and session configuration (common to iOS and Android).
  final GeneratedUserConfiguration user;
  final GeneratedSessionConfiguration session;

  // Android-only extras.
  final String? instrumentedProcessName; // Android-only.
  final bool deferredUntilForeground; // Android-only.

  GeneratedAgentConfiguration({
    required this.endpoint,
    required this.appName,
    required this.deploymentEnvironment,
    this.appVersion,
    required this.enableDebugLogging,
    required this.globalAttributes,
    // this.spanInterceptor, // Removed
    required this.user,
    required this.session,
    this.instrumentedProcessName, // Android-only.
    required this.deferredUntilForeground, // Android-only.
  });
}

// tmp needs to be here or pigeon files fails
class GeneratedEndpointConfiguration {
  final String tmp;

  GeneratedEndpointConfiguration(this.tmp);
}

class GeneratedUserConfiguration {
  final String tmp;

  GeneratedUserConfiguration(this.tmp);
}

class GeneratedSessionConfiguration {
  final String tmp;

  GeneratedSessionConfiguration(this.tmp);
}

class GeneratedSpanData {
  final String tmp;

  GeneratedSpanData(this.tmp);
}