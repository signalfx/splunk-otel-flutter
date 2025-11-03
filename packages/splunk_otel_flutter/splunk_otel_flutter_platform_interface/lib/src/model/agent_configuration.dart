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

class AgentConfiguration {
  // Required properties (common to iOS and Android).
  final EndpointConfiguration endpoint;
  final String appName;
  final String deploymentEnvironment;

  // Optional properties (common to iOS and Android).
  final String? appVersion;

  // Enables or disables debug logging. Defaults to false.
  final bool enableDebugLogging;

  // Global attributes sent with all signals.
  final MutableAttributes? globalAttributes;

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
    this.globalAttributes,
    //this.spanInterceptor,
    UserConfiguration? user,
    SessionConfiguration? session,
    this.instrumentedProcessName, // Android-only.
    this.deferredUntilForeground = false, // Android-only.
  })  : user = user ?? const UserConfiguration(),
        session = session ?? SessionConfiguration();
}

class EndpointConfiguration {
  Uri? tracesEndpoint;
  Uri? logsEndpoint;
  String? realm;
  String? rumAccessToken;

  EndpointConfiguration._internal({
    this.tracesEndpoint,
    this.logsEndpoint,
    this.realm,
    this.rumAccessToken,
  });

  factory EndpointConfiguration.forRum({
    required String realm,
    required String rumAccessToken,
  }) {
    return EndpointConfiguration._internal(
      realm: realm,
      rumAccessToken: rumAccessToken,
    );
  }

  factory EndpointConfiguration.forTraces({
    required Uri tracesEndpoint,
  }) {
    return EndpointConfiguration._internal(
      tracesEndpoint: tracesEndpoint,
    );
  }

  factory EndpointConfiguration.forTracesAndLogs({
    required Uri tracesEndpoint,
    required Uri logsEndpoint,
  }) {
    return EndpointConfiguration._internal(
      tracesEndpoint: tracesEndpoint,
      logsEndpoint: logsEndpoint,
    );
  }
}

extension GeneratedEndpointConfigurationExtension
    on GeneratedEndpointConfiguration {
  EndpointConfiguration toEndpointConfiguration() {
    return EndpointConfiguration._internal(
      tracesEndpoint: _parseUri(tracesEndpoint),
      logsEndpoint: _parseUri(logsEndpoint),
      realm: realm,
      rumAccessToken: rumAccessToken,
    );
  }
}

extension EndpointConfigurationExtension on EndpointConfiguration {
  GeneratedEndpointConfiguration toGeneratedEndpointConfiguration() {
    return GeneratedEndpointConfiguration(
      tracesEndpoint: tracesEndpoint?.toString(),
      logsEndpoint: logsEndpoint?.toString(),
      realm: realm,
      rumAccessToken: rumAccessToken,
    );
  }
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
        return GeneratedUserConfiguration(
            trackingMode: GeneratedUserTrackingMode.noTracking);
      case UserTrackingMode.anonymousTracking:
        return GeneratedUserConfiguration(
            trackingMode: GeneratedUserTrackingMode.anonymousTracking);
    }
  }
}

enum UserTrackingMode {
  noTracking,
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

class SessionConfiguration {
  final double samplingRate;

  SessionConfiguration({this.samplingRate = 1.0}) {
    if (samplingRate < 0.0 || samplingRate > 1.0) {
      throw ArgumentError(
          "samplingRate must be between 0.0 and 1.0 (inclusive). Received: $samplingRate");
    }
  }
}

class InvalidEndpointConfigurationException implements Exception {
  final String message;
  final dynamic originalError;

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

Uri _parseUri(String? uriString) {
  if (uriString == null) {
    throw InvalidEndpointConfigurationException(
        'Missing required URI string for this configuration type.');
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
