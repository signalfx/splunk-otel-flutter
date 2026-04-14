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

import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/agent_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

void main() {
  group('AgentConfiguration', () {
    test('should create with minimal required fields and defaults', () {
      // Act
      final config = AgentConfiguration(
        endpoint: EndpointConfiguration.forRum(
          realm: 'us0',
          rumAccessToken: 'token',
        ),
        appName: 'TestApp',
        deploymentEnvironment: 'production',
      );

      // Assert
      expect(config.appName, 'TestApp');
      expect(config.deploymentEnvironment, 'production');
      expect(config.endpoint?.realm, 'us0');
      expect(config.endpoint?.rumAccessToken, 'token');
      expect(config.appVersion, isNull);
      expect(config.enableDebugLogging, false);
      expect(config.user.trackingMode, UserTrackingMode.anonymousTracking);
      expect(config.session.samplingRate, 1.0);
      expect(config.instrumentedProcessName, isNull);
      expect(config.deferredUntilForeground, false);
    });

    test('should create without endpoint configuration', () {
      // Act
      final config = AgentConfiguration(
        appName: 'TestApp',
        deploymentEnvironment: 'production',
      );

      // Assert
      expect(config.endpoint, isNull);
      expect(config.appName, 'TestApp');
      expect(config.deploymentEnvironment, 'production');
    });

    test('should create without user configuration (null)', () {
      // Act
      final config = AgentConfiguration(
        endpoint: EndpointConfiguration.forRum(
          realm: 'us0',
          rumAccessToken: 'token',
        ),
        appName: 'TestApp',
        deploymentEnvironment: 'production',
        user: null,
      );

      // Assert - should use default UserConfiguration
      expect(config.user, isNotNull);
      expect(config.user.trackingMode, UserTrackingMode.anonymousTracking);
    });

    test('should create without session configuration (null)', () {
      // Act
      final config = AgentConfiguration(
        endpoint: EndpointConfiguration.forRum(
          realm: 'us0',
          rumAccessToken: 'token',
        ),
        appName: 'TestApp',
        deploymentEnvironment: 'production',
        session: null,
      );

      // Assert - should use default SessionConfiguration
      expect(config.session, isNotNull);
      expect(config.session.samplingRate, 1.0);
    });

    test('should create with custom user configuration', () {
      // Act
      final config = AgentConfiguration(
        endpoint: EndpointConfiguration.forRum(
          realm: 'us0',
          rumAccessToken: 'token',
        ),
        appName: 'TestApp',
        deploymentEnvironment: 'production',
        user: const UserConfiguration(
          trackingMode: UserTrackingMode.anonymousTracking,
        ),
      );

      // Assert
      expect(config.user.trackingMode, UserTrackingMode.anonymousTracking);
    });

    test('should create with custom session configuration', () {
      // Act
      final config = AgentConfiguration(
        endpoint: EndpointConfiguration.forRum(
          realm: 'us0',
          rumAccessToken: 'token',
        ),
        appName: 'TestApp',
        deploymentEnvironment: 'production',
        session: const SessionConfiguration(samplingRate: 0.75),
      );

      // Assert
      expect(config.session.samplingRate, 0.75);
    });

    test('should create with all optional fields', () {
      // Act
      final config = AgentConfiguration(
        endpoint: EndpointConfiguration.forRum(
          realm: 'eu0',
          rumAccessToken: 'token-123',
        ),
        appName: 'FullApp',
        deploymentEnvironment: 'staging',
        appVersion: '2.0.0',
        enableDebugLogging: true,

        user: const UserConfiguration(
          trackingMode: UserTrackingMode.anonymousTracking,
        ),
        session: const SessionConfiguration(samplingRate: 0.5),
        instrumentedProcessName: 'com.test.app',
        deferredUntilForeground: true,
      );

      // Assert
      expect(config.appVersion, '2.0.0');
      expect(config.enableDebugLogging, true);
      expect(config.user.trackingMode, UserTrackingMode.anonymousTracking);
      expect(config.session.samplingRate, 0.5);
      expect(config.instrumentedProcessName, 'com.test.app');
      expect(config.deferredUntilForeground, true);
    });

    //TODO global attributes
  });

  group('EndpointConfiguration', () {
    test('should create with realm and token', () {
      // Act
      final config = EndpointConfiguration.forRum(
        realm: 'us0',
        rumAccessToken: 'test-token',
      );

      // Assert
      expect(config.realm, 'us0');
      expect(config.rumAccessToken, 'test-token');
    });

    test('should handle different realms', () {
      // Act
      final configUS = EndpointConfiguration.forRum(realm: 'us0', rumAccessToken: 'token');
      final configEU = EndpointConfiguration.forRum(realm: 'eu0', rumAccessToken: 'token');
      final configAP = EndpointConfiguration.forRum(realm: 'ap0', rumAccessToken: 'token');

      // Assert
      expect(configUS.realm, 'us0');
      expect(configEU.realm, 'eu0');
      expect(configAP.realm, 'ap0');
    });
  });

  group('UserConfiguration', () {
    test('should default to anonymousTracking', () {
      // Act
      const config = UserConfiguration();

      // Assert
      expect(config.trackingMode, UserTrackingMode.anonymousTracking);
    });

    test('should accept anonymousTracking', () {
      // Act
      const config = UserConfiguration(
        trackingMode: UserTrackingMode.anonymousTracking,
      );

      // Assert
      expect(config.trackingMode, UserTrackingMode.anonymousTracking);
    });

    test('should accept noTracking explicitly', () {
      // Act
      const config = UserConfiguration(
        trackingMode: UserTrackingMode.noTracking,
      );

      // Assert
      expect(config.trackingMode, UserTrackingMode.noTracking);
    });
  });

  group('UserTrackingMode', () {
    test('should have exactly two values', () {
      expect(UserTrackingMode.values.length, 2);
    });

    test('should have correct enum values', () {
      expect(UserTrackingMode.values, contains(UserTrackingMode.noTracking));
      expect(UserTrackingMode.values, contains(UserTrackingMode.anonymousTracking));
    });
  });

  group('UserConfigurationExtension', () {
    test('should convert noTracking correctly', () {
      // Arrange
      const config = UserConfiguration(
        trackingMode: UserTrackingMode.noTracking,
      );

      // Act
      final generated = config.toGeneratedUserConfiguration();

      // Assert
      expect(generated.trackingMode, GeneratedUserTrackingMode.noTracking);
    });

    test('should convert anonymousTracking correctly', () {
      // Arrange
      const config = UserConfiguration(
        trackingMode: UserTrackingMode.anonymousTracking,
      );

      // Act
      final generated = config.toGeneratedUserConfiguration();

      // Assert
      expect(generated.trackingMode, GeneratedUserTrackingMode.anonymousTracking);
    });

    test('should convert default UserConfiguration correctly', () {
      // Arrange
      const config = UserConfiguration();

      // Act
      final generated = config.toGeneratedUserConfiguration();

      // Assert
      expect(
        generated.trackingMode,
        GeneratedUserTrackingMode.anonymousTracking,
      );
    });
  });

  group('SessionConfiguration Validation', () {
    test('samplingRate of 0.0 should be valid', () {
      // Act
      final config = const SessionConfiguration(samplingRate: 0.0);

      // Assert
      expect(config.samplingRate, 0.0);
    });

    test('samplingRate of 1.0 should be valid', () {
      // Act
      final config = const SessionConfiguration(samplingRate: 1.0);

      // Assert
      expect(config.samplingRate, 1.0);
    });

    test('samplingRate of 0.5 should be valid', () {
      // Act
      final config = const SessionConfiguration(samplingRate: 0.5);

      // Assert
      expect(config.samplingRate, 0.5);
    });

    test('samplingRate less than 0.0 should throw AssertionError', () {
      // Act & Assert
      expect(
        () => SessionConfiguration(samplingRate: -0.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('samplingRate greater than 1.0 should throw AssertionError', () {
      // Act & Assert
      expect(
        () => SessionConfiguration(samplingRate: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('default samplingRate should be 1.0', () {
      // Act
      const config = SessionConfiguration();

      // Assert
      expect(config.samplingRate, 1.0);
    });

    test('samplingRate out of range should throw AssertionError', () {
      // Act & Assert
      expect(
        () => SessionConfiguration(samplingRate: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('samplingRate boundary values should work', () {
      // Act
      final config0 = const SessionConfiguration(samplingRate: 0.0);
      final config1 = const SessionConfiguration(samplingRate: 1.0);

      // Assert
      expect(config0.samplingRate, 0.0);
      expect(config1.samplingRate, 1.0);
    });
  });
}