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

  factory EndpointConfiguration.fromGeneratedEndpointConfiguration({
    required GeneratedEndpointConfiguration generatedConfiguration,
  }) {
    return EndpointConfiguration(
      realm: generatedConfiguration.realm,
      rumAccessToken: generatedConfiguration.rumAccessToken,
    );
  }
}

extension EndpointConfigurationExtension on EndpointConfiguration {
  GeneratedEndpointConfiguration toGeneratedEndpointConfiguration() {
    return GeneratedEndpointConfiguration(
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
