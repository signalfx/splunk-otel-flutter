typedef SpanInterceptor = SpanData? Function(SpanData span);

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

  // Callback to filter or modify outgoing spans.
  final SpanInterceptor? spanInterceptor;

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
    this.spanInterceptor,
    UserConfiguration? user,
    SessionConfiguration? session,
    this.instrumentedProcessName, // Android-only.
    this.deferredUntilForeground = false, // Android-only.
  })  : globalAttributes = globalAttributes ?? const {},
        user = user ?? const UserConfiguration(),
        session = session ?? const SessionConfiguration();

  AgentConfiguration copyWith({
    EndpointConfiguration? endpoint,
    String? appName,
    String? deploymentEnvironment,
    String? appVersion,
    bool? enableDebugLogging,
    Map<String, Object?>? globalAttributes,
    SpanInterceptor? spanInterceptor,
    UserConfiguration? user,
    SessionConfiguration? session,
    String? instrumentedProcessName, // Android-only.
    bool? deferredUntilForeground, // Android-only.
  }) {
    return AgentConfiguration(
      endpoint: endpoint ?? this.endpoint,
      appName: appName ?? this.appName,
      deploymentEnvironment: deploymentEnvironment ?? this.deploymentEnvironment,
      appVersion: appVersion ?? this.appVersion,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      globalAttributes: globalAttributes ?? this.globalAttributes,
      spanInterceptor: spanInterceptor ?? this.spanInterceptor,
      user: user ?? this.user,
      session: session ?? this.session,
      instrumentedProcessName:
      instrumentedProcessName ?? this.instrumentedProcessName, // Android-only.
      deferredUntilForeground:
      deferredUntilForeground ?? this.deferredUntilForeground, // Android-only.
    );
  }
}

// Placeholder types to illustrate structure.
class EndpointConfiguration {
  const EndpointConfiguration();
}

class UserConfiguration {
  const UserConfiguration();
}

class SessionConfiguration {
  const SessionConfiguration();
}

class SpanData {}