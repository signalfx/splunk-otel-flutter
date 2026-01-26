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
import 'package:splunk_otel_flutter_platform_interface/src/implementation/splunk_otel_flutter_platform_implementation.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/agent_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/module_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/mutable_attributes.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/status.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';
import '../mock_splunk_otel_flutter_platform_interface_host_api.dart';
import '../pigeon/test_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Splunk OpenTelemetry Flutter Integration Tests', () {
    late SplunkOtelFlutterPlatformImplementation implementation;
    late MockSplunkOtelFlutterPlatformInterfaceHostApi mockApi;

    setUp(() {
      mockApi = MockSplunkOtelFlutterPlatformInterfaceHostApi();
      TestSplunkOtelFlutterHostApi.setUp(mockApi);
      implementation = SplunkOtelFlutterPlatformImplementation.instance;
    });

    tearDown(() {
      TestSplunkOtelFlutterHostApi.setUp(null);
    });

    group('Full Installation Flow', () {
      test('should complete full installation with all configurations', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'test-token-abc123',
          ),
          appName: 'IntegrationTestApp',
          deploymentEnvironment: 'production',
          appVersion: '1.0.0',
          enableDebugLogging: true,
          user: const UserConfiguration(
            trackingMode: UserTrackingMode.anonymousTracking,
          ),
          session: SessionConfiguration(samplingRate: 0.75),
          instrumentedProcessName: 'com.example.integration.test',
          deferredUntilForeground: true,
        );

        final navConfig = NavigationModuleConfiguration(
          isEnabled: true,
          isAutomatedTrackingEnabled: true,
        );

        final slowRenderingConfig = SlowRenderingModuleConfiguration(
          isEnabled: true,
          interval: const Duration(milliseconds: 1500),
        );

        bool installCalled = false;
        mockApi.installHandler = (genAgent, genNav, genSlow, genCrash, genInteractions, genNetwork, genAnr, genHttpUrl, genOkHttp3, genNetworkInst) async {
          installCalled = true;

          // Verify agent configuration
          expect(genAgent.appName, 'IntegrationTestApp');
          expect(genAgent.deploymentEnvironment, 'production');
          expect(genAgent.endpoint.realm, 'us0');
          expect(genAgent.endpoint.rumAccessToken, 'test-token-abc123');
          expect(genAgent.appVersion, '1.0.0');
          expect(genAgent.enableDebugLogging, true);
          expect(genAgent.user?.trackingMode,
              GeneratedUserTrackingMode.anonymousTracking);
          expect(genAgent.session?.samplingRate, 0.75);
          expect(genAgent.instrumentedProcessName, 'com.example.integration.test');
          expect(genAgent.deferredUntilForeground, true);

          // Verify navigation configuration
          expect(genNav?.isEnabled, true);
          expect(genNav?.isAutomatedTrackingEnabled, true);

          // Verify slow rendering configuration
          expect(genSlow?.isEnabled, true);
          expect(genSlow?.intervalMillis, 1500);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [navConfig, slowRenderingConfig],
        );

        // Assert
        expect(installCalled, true);
      });

      test('should handle minimal configuration installation', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'eu0',
            rumAccessToken: 'minimal-token',
          ),
          appName: 'MinimalApp',
          deploymentEnvironment: 'development',
        );

        bool installCalled = false;
        mockApi.installHandler = (genAgent, genNav, genSlow, genCrash, genInteractions, genNetwork, genAnr, genHttpUrl, genOkHttp3, genNetworkInst) async {
          installCalled = true;

          // Verify minimal agent config
          expect(genAgent.appName, 'MinimalApp');
          expect(genAgent.appVersion, isNull);
          expect(genAgent.enableDebugLogging, false);

          // Verify no module configs provided (should be null)
          expect(genNav, isNull);
          expect(genSlow, isNull);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );

        // Assert
        expect(installCalled, true);
      });

      test('should handle installation with only navigation module', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'NavOnlyApp',
          deploymentEnvironment: 'staging',
        );

        final navConfig = NavigationModuleConfiguration(
          isEnabled: false,
          isAutomatedTrackingEnabled: false,
        );

        mockApi.installHandler = (_, genNav, genSlow, genCrash, genInteractions, genNetwork, genAnr, genHttpUrl, genOkHttp3, genNetworkInst) async {
          expect(genNav?.isEnabled, false);
          expect(genNav?.isAutomatedTrackingEnabled, false);
          // No slow rendering module provided
          expect(genSlow, isNull);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [navConfig],
        );
      });

      test('should handle installation with only slow rendering module', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'SlowRenderApp',
          deploymentEnvironment: 'production',
        );

        final slowConfig = SlowRenderingModuleConfiguration(
          isEnabled: false,
          interval: const Duration(milliseconds: 250),
        );

        mockApi.installHandler = (_, genNav, genSlow, genCrash, genInteractions, genNetwork, genAnr, genHttpUrl, genOkHttp3, genNetworkInst) async {
          // No navigation module provided
          expect(genNav, isNull);
          expect(genSlow?.isEnabled, false);
          expect(genSlow?.intervalMillis, 250);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [slowConfig],
        );
      });
    });

    group('Configuration Validation Integration', () {
      test('should reject invalid sampling rate during installation', () async {
        // Arrange & Assert
        expect(
              () => AgentConfiguration(
            endpointConfiguration: EndpointConfiguration.forRum(
              realm: 'us0',
              rumAccessToken: 'token',
            ),
            appName: 'InvalidApp',
            deploymentEnvironment: 'test',
            session: SessionConfiguration(samplingRate: 1.5),
          ),
          throwsArgumentError,
        );
      });

      test('should handle edge case sampling rates correctly', () async {
        // Test 0.0
        final config0 = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'App',
          deploymentEnvironment: 'test',
          session: SessionConfiguration(samplingRate: 0.0),
        );

        mockApi.installHandler = (genAgent, _, _, _, _, _, _, _, _, _) async {
          expect(genAgent.session?.samplingRate, 0.0);
        };

        await implementation.install(
          agentConfiguration: config0,
          moduleConfigurations: [],
        );

        // Test 1.0
        final config1 = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'App',
          deploymentEnvironment: 'test',
          session: SessionConfiguration(samplingRate: 1.0),
        );

        mockApi.installHandler = (genAgent, _, _, _, _, _, _, _, _, _) async {
          expect(genAgent.session?.samplingRate, 1.0);
        };

        await implementation.install(
          agentConfiguration: config1,
          moduleConfigurations: [],
        );
      });
    });

    group('User Tracking Mode Integration', () {
      test('should handle user tracking mode transitions', () async {
        // Test noTracking
        final configNoTracking = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'TrackingApp',
          deploymentEnvironment: 'test',
          user: const UserConfiguration(
            trackingMode: UserTrackingMode.noTracking,
          ),
        );

        mockApi.installHandler = (genAgent, _, _, _, _, _, _, _, _, _) async {
          expect(genAgent.user?.trackingMode,
              GeneratedUserTrackingMode.noTracking);
        };

        await implementation.install(
          agentConfiguration: configNoTracking,
          moduleConfigurations: [],
        );

        // Test anonymousTracking
        final configAnonymous = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'TrackingApp',
          deploymentEnvironment: 'test',
          user: const UserConfiguration(
            trackingMode: UserTrackingMode.anonymousTracking,
          ),
        );

        mockApi.installHandler = (genAgent, _, _, _, _, _, _, _, _, _) async {
          expect(genAgent.user?.trackingMode,
              GeneratedUserTrackingMode.anonymousTracking);
        };

        await implementation.install(
          agentConfiguration: configAnonymous,
          moduleConfigurations: [],
        );

        // Test defaultTracking
        final configDefault = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'TrackingApp',
          deploymentEnvironment: 'test',
        );

        mockApi.installHandler = (genAgent, _, _, _, _, _, _, _, _, _) async {
          expect(genAgent.user?.trackingMode,
              GeneratedUserTrackingMode.noTracking);
        };

        await implementation.install(
          agentConfiguration: configDefault,
          moduleConfigurations: [],
        );
      });
    });


    group('Module Configuration Priority', () {
      test('should use first module configuration when duplicates exist', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'DuplicateModulesApp',
          deploymentEnvironment: 'test',
        );

        final navConfig1 = NavigationModuleConfiguration(
          isEnabled: true,
          isAutomatedTrackingEnabled: true,
        );

        final navConfig2 = NavigationModuleConfiguration(
          isEnabled: false,
          isAutomatedTrackingEnabled: false,
        );

        mockApi.installHandler = (_, genNav, _, _, _, _, _, _, _, _) async {
          // Should use first one (navConfig1)
          expect(genNav?.isEnabled, true);
          expect(genNav?.isAutomatedTrackingEnabled, true);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [navConfig1, navConfig2],
        );
      });
    });

    group('Android-Specific Configuration', () {
      test('should handle Android-specific options correctly', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'android-token',
          ),
          appName: 'AndroidApp',
          deploymentEnvironment: 'production',
          instrumentedProcessName: 'com.example.android.app',
          deferredUntilForeground: true,
        );

        mockApi.installHandler = (genAgent, _, _, _, _, _, _, _, _, _) async {
          expect(genAgent.instrumentedProcessName, 'com.example.android.app');
          expect(genAgent.deferredUntilForeground, true);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );
      });

      test('should handle null Android-specific options', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'CrossPlatformApp',
          deploymentEnvironment: 'production',
          instrumentedProcessName: null,
          deferredUntilForeground: false,
        );

        mockApi.installHandler = (genAgent, _, _, _, _, _, _, _, _, _) async {
          expect(genAgent.instrumentedProcessName, isNull);
          expect(genAgent.deferredUntilForeground, false);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );
      });
    });

    group('Duration Conversion Integration', () {
      test('should correctly convert various duration formats', () async {
        // Arrange
        final testCases = [
          (Duration.zero, 0),
          (const Duration(milliseconds: 100), 100),
          (const Duration(seconds: 1), 1000),
          (const Duration(seconds: 1, milliseconds: 500), 1500),
          (const Duration(minutes: 1), 60000),
        ];

        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'DurationApp',
          deploymentEnvironment: 'test',
        );

        for (final (duration, expectedMillis) in testCases) {
          final slowConfig = SlowRenderingModuleConfiguration(
            interval: duration,
          );

          mockApi.installHandler = (_, _, genSlow, _, _, _, _, _, _, _) async {
            expect(genSlow?.intervalMillis, expectedMillis);
          };

          await implementation.install(
            agentConfiguration: agentConfig,
            moduleConfigurations: [slowConfig],
          );
        }
      });
    });

    group('Error Handling', () {
      test('should propagate platform errors during installation', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'ErrorApp',
          deploymentEnvironment: 'test',
        );

        mockApi.installHandler = (_, _, _, _, _, _, _, _, _, _) async {
          throw Exception('Platform installation failed');
        };

        // Act & Assert
        expect(
              () => implementation.install(
            agentConfiguration: agentConfig,
            moduleConfigurations: [],
          ),
          throwsException,
        );
      });

      test('should propagate errors during getSessionId', () async {
        // Arrange
        mockApi.sessionStateGetIdHandler = () async {
          throw Exception('Failed to get session ID');
        };

        // Act & Assert
        expect(
              () => implementation.sessionStateGetId(),
          throwsException,
        );
      });
    });

    group('Global Attributes Integration', () {
      test('should set and get string attribute', () async {
        const key = 'user_id';
        const value = 'user-123';

        mockApi.globalAttributesSetStringHandler = (k, v) async {
          expect(k, key);
          expect(v, value);
        };

        mockApi.globalAttributesGetHandler = (k) async {
          expect(k, key);
          return GeneratedMutableAttributeString(value: value);
        };

        await implementation.globalAttributesSetString(key: key, value: value);
        final result = await implementation.globalAttributesGet(key: key);

        expect(result, isA<MutableAttributeString>());
        expect((result as MutableAttributeString).value, value);
      });

      test('should set and get int attribute', () async {
        const key = 'user_age';
        const value = 25;

        mockApi.globalAttributesSetIntHandler = (k, v) async {
          expect(k, key);
          expect(v, value);
        };

        mockApi.globalAttributesGetHandler = (k) async {
          expect(k, key);
          return GeneratedMutableAttributeInt(value: value);
        };

        await implementation.globalAttributesSetInt(key: key, value: value);
        final result = await implementation.globalAttributesGet(key: key);

        expect(result, isA<MutableAttributeInt>());
        expect((result as MutableAttributeInt).value, value);
      });

      test('should set and get double attribute', () async {
        const key = 'price';
        const value = 99.99;

        mockApi.globalAttributesSetDoubleHandler = (k, v) async {
          expect(k, key);
          expect(v, value);
        };

        mockApi.globalAttributesGetHandler = (k) async {
          expect(k, key);
          return GeneratedMutableAttributeDouble(value: value);
        };

        await implementation.globalAttributesSetDouble(key: key, value: value);
        final result = await implementation.globalAttributesGet(key: key);

        expect(result, isA<MutableAttributeDouble>());
        expect((result as MutableAttributeDouble).value, value);
      });

      test('should set and get bool attribute', () async {
        const key = 'is_premium';
        const value = true;

        mockApi.globalAttributesSetBoolHandler = (k, v) async {
          expect(k, key);
          expect(v, value);
        };

        mockApi.globalAttributesGetHandler = (k) async {
          expect(k, key);
          return GeneratedMutableAttributeBool(value: value);
        };

        await implementation.globalAttributesSetBool(key: key, value: value);
        final result = await implementation.globalAttributesGet(key: key);

        expect(result, isA<MutableAttributeBool>());
        expect((result as MutableAttributeBool).value, value);
      });

      test('should check if attribute contains key', () async {
        const key = 'user_id';

        mockApi.globalAttributesContainsHandler = (k) async {
          expect(k, key);
          return true;
        };

        final result = await implementation.globalAttributesContains(key: key);
        expect(result, true);
      });

      test('should remove attribute', () async {
        const key = 'user_id';

        mockApi.globalAttributesRemoveHandler = (k) async {
          expect(k, key);
        };

        await implementation.globalAttributesRemove(key: key);
      });

      test('should remove all attributes', () async {
        bool removeCalled = false;

        mockApi.globalAttributesRemoveAllHandler = () async {
          removeCalled = true;
        };

        await implementation.globalAttributesRemoveAll();
        expect(removeCalled, true);
      });

      test('should get all attributes', () async {
        mockApi.globalAttributesGetAllHandler = () async {
          return GeneratedMutableAttributes(attributes: {
            'key1': GeneratedMutableAttributeString(value: 'value1'),
            'key2': GeneratedMutableAttributeInt(value: 42),
          });
        };

        final result = await implementation.globalAttributesGetAll();
        
        expect(result.attributes.length, 2);
        expect(result.attributes['key1'], isA<MutableAttributeString>());
        expect((result.attributes['key1'] as MutableAttributeString).value, 'value1');
        expect(result.attributes['key2'], isA<MutableAttributeInt>());
        expect((result.attributes['key2'] as MutableAttributeInt).value, 42);
      });

      test('should set all attributes', () async {
        final attributes = MutableAttributes(attributes: {
          'key1': MutableAttributeString(value: 'value1'),
          'key2': MutableAttributeInt(value: 42),
        });

        mockApi.globalAttributesSetAllHandler = (value) async {
          expect(value.attributes.length, 2);
          expect(value.attributes['key1'], isA<GeneratedMutableAttributeString>());
          expect(value.attributes['key2'], isA<GeneratedMutableAttributeInt>());
        };

        await implementation.globalAttributesSetAll(attributes: attributes);
      });
    });

    group('State Getters Integration', () {
      test('should get all state values', () async {
        mockApi.stateGetAppNameHandler = () async => 'TestApp';
        mockApi.stateGetAppVersionHandler = () async => '2.0.0';
        mockApi.stateGetDeploymentEnvironmentHandler = () async => 'staging';
        mockApi.stateGetIsDebugLoggingEnabledHandler = () async => true;
        mockApi.stateGetInstrumentedProcessNameHandler = () async => 'com.test.app';
        mockApi.stateGetDeferredUntilForegroundHandler = () async => true;
        mockApi.stateGetStatusHandler = () async => GeneratedStatus.running;
        mockApi.stateGetEndpointConfigurationHandler = () async {
          return GeneratedEndpointConfiguration(
            realm: 'eu0',
            rumAccessToken: 'token-xyz',
          );
        };

        expect(await implementation.stateGetAppName(), 'TestApp');
        expect(await implementation.stateGetAppVersion(), '2.0.0');
        expect(await implementation.stateGetDeploymentEnvironment(), 'staging');
        expect(await implementation.stateGetIsDebugLoggingEnabled(), true);
        expect(await implementation.stateGetInstrumentedProcessName(), 'com.test.app');
        expect(await implementation.stateGetDeferredUntilForeground(), true);
        expect(await implementation.stateGetStatus(), Status.running);

        final endpoint = await implementation.stateGetEndpointConfiguration();
        expect(endpoint.realm, 'eu0');
        expect(endpoint.rumAccessToken, 'token-xyz');
      });
    });

    group('Session State Integration', () {
      test('should get session id and sampling rate', () async {
        mockApi.sessionStateGetIdHandler = () async => 'session-abc-123';
        mockApi.sessionStateGetSamplingRateHandler = () async => 0.5;

        expect(await implementation.sessionStateGetId(), 'session-abc-123');
        expect(await implementation.sessionStateGetSamplingRate(), 0.5);
      });
    });

    group('User Tracking Integration', () {
      test('should get user tracking mode state', () async {
        mockApi.userStateGetUserTrackingModeHandler = () async {
          return GeneratedUserTrackingMode.anonymousTracking;
        };

        final mode = await implementation.userStateGetUserTrackingMode();
        expect(mode, UserTrackingMode.anonymousTracking);
      });

      test('should get and set user tracking mode preferences', () async {
        mockApi.userPreferencesGetUserTrackingModeHandler = () async {
          return GeneratedUserTrackingMode.noTracking;
        };

        mockApi.userPreferencesSetUserTrackingModeHandler = (mode) async {
          expect(mode, GeneratedUserTrackingMode.anonymousTracking);
        };

        final mode = await implementation.userPreferencesGetUserTrackingMode();
        expect(mode, UserTrackingMode.noTracking);

        await implementation.userPreferencesSetUserTrackingMode(
          userTrackingMode: UserTrackingMode.anonymousTracking,
        );
      });
    });

    group('Custom Tracking Integration', () {
      test('should track custom event', () async {
        const eventName = 'button_clicked';
        final attributes = MutableAttributes(attributes: {
          'button_id': MutableAttributeString(value: 'submit_btn'),
          'click_count': MutableAttributeInt(value: 5),
        });

        mockApi.customTrackingTrackCustomEventHandler = (name, attrs) async {
          expect(name, eventName);
          expect(attrs.attributes.length, 2);
        };

        await implementation.customTrackingTrackCustomEvent(
          name: eventName,
          attributes: attributes,
        );
      });

      test('should start and end workflow', () async {
        const workflowName = 'checkout_flow';
        int? receivedHandle;

        mockApi.customTrackingStartWorkflowHandler = (name) async {
          expect(name, workflowName);
          return 789; // Return a mock handle
        };

        mockApi.customTrackingEndWorkflowHandler = (handle) async {
          receivedHandle = handle;
        };

        final handle = await implementation.customTrackingStartWorkflow(workflowName: workflowName);
        expect(handle, 789);

        await implementation.customTrackingEndWorkflow(handle: handle);
        expect(receivedHandle, 789);
      });
    });

    group('Navigation Tracking Integration', () {
      test('should track screen navigation', () async {
        const screenName = 'HomeScreen';

        mockApi.navigationTrackHandler = (name) async {
          expect(name, screenName);
        };

        await implementation.navigationTrack(screenName: screenName);
      });
    });
  });
}
