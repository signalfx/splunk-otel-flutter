import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

class AgentConfiguration {
  // Required properties (common to iOS and Android).
  final EndpointConfiguration endpoint;
  final String appName;
  final String deploymentEnvironment;

  // Optional properties (common to iOS and Android).
  // On iOS, this typically defaults to CFBundleShortVersionString.
  final String? appVersion;

  // Enables or disables debug logging. Defaults to false.
  final bool enableDebugLogging;

  // Global attributes sent with all signals.
  // iOS: MutableAttributes; Android: Attributes. Represented here as a map.
  final Map<String, Object?> globalAttributes;

  // TBD in future
  // final SpanInterceptor? spanInterceptor;

  // User and session configuration (common to iOS and Android).
  final UserConfiguration user;
  final SessionConfiguration session;

  // Android-only extras.
  final String? instrumentedProcessName; // Android-only.
  final bool deferredUntilForeground; // Android-only.

  AgentConfiguration({
    required this.endpoint,
    required this.appName,
    required this.deploymentEnvironment,
    this.appVersion,
    this.enableDebugLogging = false,
    Map<String, Object?>? globalAttributes,
    //this.spanInterceptor,
    UserConfiguration? user,
    SessionConfiguration? session,
    this.instrumentedProcessName, // Android-only.
    this.deferredUntilForeground = false, // Android-only.
  })  : globalAttributes = globalAttributes ?? const {},
        user = user ?? const UserConfiguration(),
        session = session ?? SessionConfiguration();
}

class EndpointConfiguration {
  final String realm;
  final String rumAccessToken;

  const EndpointConfiguration({
    required this.realm,
    required this.rumAccessToken,
  });
}

class UserConfiguration {
  final UserTrackingMode trackingMode;

  const UserConfiguration({
    this.trackingMode = UserTrackingMode.noTracking,
  });
}

extension UserConfigurationExtension on UserConfiguration {
  GeneratedUserConfiguration toGeneratedUserConfiguration() {
    switch (trackingMode) {
      case UserTrackingMode.noTracking:
        return GeneratedUserConfiguration(trackingMode: GeneratedUserTrackingMode.noTracking);
      case UserTrackingMode.anonymousTracking:
        return GeneratedUserConfiguration(trackingMode: GeneratedUserTrackingMode.anonymousTracking);
      }
  }
}

enum UserTrackingMode {
  noTracking,
  anonymousTracking,
}

class SessionConfiguration {
  final double samplingRate;

  SessionConfiguration({this.samplingRate = 1.0}) {
    if (samplingRate < 0.0 || samplingRate > 1.0) {
      throw ArgumentError(
          "samplingRate must be between 0.0 and 1.0 (inclusive). Received: $samplingRate");
    }
  }
}
