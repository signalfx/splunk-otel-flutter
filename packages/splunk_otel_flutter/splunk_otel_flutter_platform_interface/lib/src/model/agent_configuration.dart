/*
 * Copyright 2025 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

/// Configuration for the Splunk OpenTelemetry agent.
///
/// This class holds all configuration parameters needed to initialize and run
/// the Splunk RUM agent on both Android and iOS platforms.
///
/// Example:
/// ```dart
/// final config = AgentConfiguration(
///   endpointConfiguration: EndpointConfiguration.forRum(
///     realm: 'us0',
///     rumAccessToken: 'your-token',
///   ),
///   appName: 'MyApp',
///   deploymentEnvironment: 'production',
/// );
/// ```
class AgentConfiguration {
  /// Backend endpoint configuration for sending telemetry data.
  final EndpointConfiguration endpointConfiguration;
  
  /// The name of your application.
  final String appName;
  
  /// The deployment environment (e.g., 'production', 'staging', 'dev').
  final String deploymentEnvironment;

  /// The version of your application. Optional.
  final String? appVersion;

  /// Enables or disables debug logging. Defaults to false.
  final bool enableDebugLogging;

  /// Global attributes sent with all signals.
  final MutableAttributes? globalAttributes;

  // TBD in future
  // final SpanInterceptor? spanInterceptor;

  /// User tracking configuration.
  final UserConfiguration user;
  
  /// Session sampling configuration.
  final SessionConfiguration session;

  /// **Android only.** Name of the process to instrument. Optional.
  final String? instrumentedProcessName;
  
  /// **Android only.** Whether to defer initialization until app foreground. Defaults to false.
  final bool deferredUntilForeground;

  /// Creates an agent configuration.
  AgentConfiguration({
    required this.endpointConfiguration,
    required this.appName,
    required this.deploymentEnvironment,
    this.appVersion,
    this.enableDebugLogging = false,
    this.globalAttributes,
    //this.spanInterceptor,
    UserConfiguration? user,
    SessionConfiguration? session,
    this.instrumentedProcessName, // Android-only.
    this.deferredUntilForeground = false, // Android-only.
  })  : user = user ?? const UserConfiguration(),
        session = session ?? SessionConfiguration();
}

/// Configuration for telemetry data endpoints.
///
/// Defines where telemetry data (traces, session replays) should be sent.
/// Use one of the factory constructors to create an instance.
class EndpointConfiguration {
  /// Custom trace endpoint URL.
  Uri? traceEndpoint;
  
  /// Custom session replay endpoint URL.
  Uri? sessionReplayEndpoint;
  
  /// Splunk realm (e.g., 'us0', 'us1', 'eu0').
  String? realm;
  
  /// RUM access token for authentication.
  String? rumAccessToken;

  EndpointConfiguration._internal({
    this.traceEndpoint,
    this.sessionReplayEndpoint,
    this.realm,
    this.rumAccessToken,
  });

  /// Creates endpoint configuration for Splunk RUM using realm and token.
  ///
  /// This is the recommended approach for production deployments using
  /// Splunk Observability Cloud.
  ///
  /// Example:
  /// ```dart
  /// EndpointConfiguration.forRum(
  ///   realm: 'us0',
  ///   rumAccessToken: 'your-token-here',
  /// )
  /// ```
  factory EndpointConfiguration.forRum({
    required String realm,
    required String rumAccessToken,
  }) {
    return EndpointConfiguration._internal(
      realm: realm,
      rumAccessToken: rumAccessToken,
    );
  }

  /// Creates endpoint configuration with a custom traces endpoint.
  ///
  /// Use this for self-hosted or custom backend deployments.
  factory EndpointConfiguration.forTraces({
    required Uri tracesEndpoint,
  }) {
    return EndpointConfiguration._internal(
      traceEndpoint: tracesEndpoint,
    );
  }

  /// Creates endpoint configuration with custom traces and session replay endpoints.
  ///
  /// Use this for self-hosted or custom backend deployments with session replay support.
  factory EndpointConfiguration.forTracesAndSessionReplay({
    required Uri traceEndpoint,
    required Uri sessionReplayEndpoint,
  }) {
    return EndpointConfiguration._internal(
      traceEndpoint: traceEndpoint,
      sessionReplayEndpoint: sessionReplayEndpoint,
    );
  }
}

extension GeneratedEndpointConfigurationExtension
    on GeneratedEndpointConfiguration {
  EndpointConfiguration toEndpointConfiguration() {
    return EndpointConfiguration._internal(
      traceEndpoint: _parseUri(traceEndpoint),
      sessionReplayEndpoint: _parseUri(sessionReplayEndpoint),
      realm: realm,
      rumAccessToken: rumAccessToken,
    );
  }
}

extension EndpointConfigurationExtension on EndpointConfiguration {
  GeneratedEndpointConfiguration toGeneratedEndpointConfiguration() {
    return GeneratedEndpointConfiguration(
      traceEndpoint: traceEndpoint?.toString(),
      sessionReplayEndpoint: sessionReplayEndpoint?.toString(),
      realm: realm,
      rumAccessToken: rumAccessToken,
    );
  }
}

/// Configuration for user tracking behavior.
///
/// Controls how user information is tracked and reported.
class UserConfiguration {
  /// The user tracking mode.
  final UserTrackingMode trackingMode;

  /// Creates a user configuration with the specified tracking mode.
  ///
  /// Defaults to [UserTrackingMode.noTracking].
  const UserConfiguration({
    this.trackingMode = UserTrackingMode.noTracking,
  });
}

extension UserConfigurationExtension on UserConfiguration {
  GeneratedUserConfiguration toGeneratedUserConfiguration() {
    switch (trackingMode) {
      case UserTrackingMode.noTracking:
        return GeneratedUserConfiguration(
            trackingMode: GeneratedUserTrackingMode.noTracking);
      case UserTrackingMode.anonymousTracking:
        return GeneratedUserConfiguration(
            trackingMode: GeneratedUserTrackingMode.anonymousTracking);
    }
  }
}

/// Defines how user information is tracked.
enum UserTrackingMode {
  /// No user tracking. User-specific data is not collected.
  noTracking,
  
  /// Anonymous user tracking. Collects user data without personal identifiers.
  anonymousTracking,
}

extension UserTrackingModeExtension on UserTrackingMode {
  GeneratedUserTrackingMode toGeneratedUserTrackingMode() {
    switch (this) {
      case UserTrackingMode.noTracking:
        return GeneratedUserTrackingMode.noTracking;
      case UserTrackingMode.anonymousTracking:
        return GeneratedUserTrackingMode.anonymousTracking;
    }
  }
}

/// Configuration for session sampling.
///
/// Controls what percentage of sessions are sampled and sent to the backend.
class SessionConfiguration {
  /// The sampling rate for sessions. Must be between 0.0 and 1.0.
  ///
  /// A value of 1.0 means all sessions are sampled (100%).
  /// A value of 0.5 means half of sessions are sampled (50%).
  /// Defaults to 1.0.
  final double samplingRate;

  /// Creates a session configuration with the specified sampling rate.
  ///
  /// Throws [ArgumentError] if [samplingRate] is not between 0.0 and 1.0.
  SessionConfiguration({this.samplingRate = 1.0}) {
    if (samplingRate < 0.0 || samplingRate > 1.0) {
      throw ArgumentError(
          "samplingRate must be between 0.0 and 1.0 (inclusive). Received: $samplingRate");
    }
  }
}

/// Exception thrown when endpoint configuration is invalid.
///
/// This typically occurs when a URI string cannot be parsed or is malformed.
class InvalidEndpointConfigurationException implements Exception {
  /// The error message describing what went wrong.
  final String message;
  
  /// The original error that caused this exception, if any.
  final dynamic originalError;

  /// Creates an invalid endpoint configuration exception.
  InvalidEndpointConfigurationException(this.message, {this.originalError});

  @override
  String toString() {
    String result = 'InvalidEndpointConfigurationException: $message';
    if (originalError != null) {
      result += '\nOriginal error: $originalError';
    }
    return result;
  }
}

Uri? _parseUri(String? uriString) {
  if (uriString == null) {
    return null;
  }

  try {
    return Uri.parse(uriString);
  } on FormatException catch (e) {
    throw InvalidEndpointConfigurationException(
      'Invalid URI format: "$uriString".',
      originalError: e,
    );
  }
}
