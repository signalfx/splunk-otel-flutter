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

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter_platform_interface/src/implementation/splunk_otel_flutter_platform_implementation.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/agent_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/module_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/mutable_attributes.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/session_replay.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/status.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';
import '../../mock_splunk_otel_flutter_platform_interface_host_api.dart';
import '../../pigeon/test_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplunkOtelFlutterPlatformImplementation', () {
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

    group('Singleton', () {
      test('should return same instance', () {
        final instance1 = SplunkOtelFlutterPlatformImplementation.instance;
        final instance2 = SplunkOtelFlutterPlatformImplementation.instance;

        expect(identical(instance1, instance2), true);
      });
    });

    group('Install', () {
      test('should call install with correct agent configuration', () async {
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'TestApp',
          deploymentEnvironment: 'test',
        );

        bool installCalled = false;
        mockApi.installHandler = (genAgent, _, _, _, _, _, _, _, _, _) async {
          installCalled = true;
          expect(genAgent.appName, 'TestApp');
          expect(genAgent.deploymentEnvironment, 'test');
        };

        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );

        expect(installCalled, true);
      });

      test('should handle module configurations extraction', () async {
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'TestApp',
          deploymentEnvironment: 'test',
        );

        final navConfig = NavigationModuleConfiguration(isEnabled: true);
        final slowConfig = SlowRenderingModuleConfiguration(isEnabled: false);

        mockApi.installHandler = (genAgent, genNav, genSlow, genCrash, genInteractions, genNetwork, genAnr, genHttpUrl, genOkHttp3, genNetworkInst) async {
          expect(genNav?.isEnabled, true);
          expect(genSlow?.isEnabled, false);
          expect(genCrash, isNull);
        };

        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [navConfig, slowConfig],
        );
      });

      test('should handle all module types', () async {
        final agentConfig = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'TestApp',
          deploymentEnvironment: 'test',
        );

        final moduleConfigs = [
          NavigationModuleConfiguration(),
          SlowRenderingModuleConfiguration(),
          CrashReportsModuleConfiguration(),
          InteractionsModuleConfiguration(),
          NetworkMonitorModuleConfiguration(),
          AnrModuleConfiguration(),
          HttpUrlModuleConfiguration(),
          OkHttp3AutoModuleConfiguration(),
          NetworkInstrumentationModuleConfiguration(),
        ];

        mockApi.installHandler = (genAgent, genNav, genSlow, genCrash, genInteractions, genNetwork, genAnr, genHttpUrl, genOkHttp3, genNetworkInst) async {
          expect(genNav, isNotNull);
          expect(genSlow, isNotNull);
          expect(genCrash, isNotNull);
          expect(genInteractions, isNotNull);
          expect(genNetwork, isNotNull);
          expect(genAnr, isNotNull);
          expect(genHttpUrl, isNotNull);
          expect(genOkHttp3, isNotNull);
          expect(genNetworkInst, isNotNull);
        };

        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: moduleConfigs,
        );
      });
    });

    group('State Getters', () {
      test('should get app name', () async {
        mockApi.stateGetAppNameHandler = () async => 'MyApp';
        expect(await implementation.stateGetAppName(), 'MyApp');
      });

      test('should get app version', () async {
        mockApi.stateGetAppVersionHandler = () async => '1.2.3';
        expect(await implementation.stateGetAppVersion(), '1.2.3');
      });

      test('should get deployment environment', () async {
        mockApi.stateGetDeploymentEnvironmentHandler = () async => 'production';
        expect(await implementation.stateGetDeploymentEnvironment(), 'production');
      });

      test('should get debug logging enabled', () async {
        mockApi.stateGetIsDebugLoggingEnabledHandler = () async => true;
        expect(await implementation.stateGetIsDebugLoggingEnabled(), true);
      });

      test('should get instrumented process name', () async {
        mockApi.stateGetInstrumentedProcessNameHandler = () async => 'com.example.app';
        expect(await implementation.stateGetInstrumentedProcessName(), 'com.example.app');
      });

      test('should get deferred until foreground', () async {
        mockApi.stateGetDeferredUntilForegroundHandler = () async => true;
        expect(await implementation.stateGetDeferredUntilForeground(), true);
      });

      test('should get status', () async {
        mockApi.stateGetStatusHandler = () async => GeneratedStatus.running;
        expect(await implementation.stateGetStatus(), Status.running);
      });

      test('should get endpoint configuration', () async {
        mockApi.stateGetEndpointConfigurationHandler = () async {
          return GeneratedEndpointConfiguration(
            realm: 'eu0',
            rumAccessToken: 'token123',
          );
        };

        final endpoint = await implementation.stateGetEndpointConfiguration();
        expect(endpoint.realm, 'eu0');
        expect(endpoint.rumAccessToken, 'token123');
      });
    });

    group('Session Replay', () {
      test('should start session replay', () async {
        bool called = false;
        mockApi.sessionReplayStartHandler = () async {
          called = true;
        };

        await implementation.sessionReplayStart();
        expect(called, true);
      });

      test('should stop session replay', () async {
        bool called = false;
        mockApi.sessionReplayStopHandler = () async {
          called = true;
        };

        await implementation.sessionReplayStop();
        expect(called, true);
      });

      test('should get session replay status', () async {
        mockApi.sessionReplayStateGetStatusHandler = () async {
          return GeneratedSessionReplayStatus.isRecording;
        };

        final status = await implementation.sessionReplayStateGetStatus();
        expect(status, SessionReplayStatus.isRecording);
      });

      test('should get state rendering mode', () async {
        mockApi.sessionReplayStateGetRenderingModeHandler = () async {
          return GeneratedRenderingMode.wireframeOnly;
        };

        final mode = await implementation.sessionReplayStateGetRenderingMode();
        expect(mode, RenderingMode.wireframeOnly);
      });

      test('should get preferences rendering mode', () async {
        mockApi.sessionReplayPreferencesGetRenderingModeHandler = () async {
          return GeneratedRenderingMode.native;
        };

        final mode = await implementation.sessionReplayPreferencesGetRenderingMode();
        expect(mode, RenderingMode.native);
      });

      test('should set preferences rendering mode', () async {
        GeneratedRenderingMode? receivedMode;
        mockApi.sessionReplayPreferencesSetRenderingModeHandler = (mode) async {
          receivedMode = mode;
        };

        await implementation.sessionReplayPreferencesSetRenderingMode(
          renderingMode: RenderingMode.wireframeOnly,
        );
        expect(receivedMode, GeneratedRenderingMode.wireframeOnly);
      });

      test('should get recording mask', () async {
        mockApi.sessionReplayGetRecordingMaskHandler = () async {
          return GeneratedRecordingMaskList(recordingMaskList: [
            GeneratedRecordingMaskElement(
              rect: GeneratedRect(left: 0, top: 0, width: 100, height: 100),
              type: GeneratedRecordingMaskType.erasing,
            ),
          ]);
        };

        final mask = await implementation.sessionReplayGetRecordingMask();
        expect(mask?.elements.length, 1);
        expect(mask?.elements.first.type, RecordingMaskType.erasing);
      });

      test('should set recording mask', () async {
        GeneratedRecordingMaskList? receivedMask;
        mockApi.sessionReplaySetRecordingMaskHandler = (mask) async {
          receivedMask = mask;
        };

        final recordingMask = RecordingMaskList(elements: [
          RecordingMaskElement(
            rect: const Rect.fromLTWH(0, 0, 100, 100),
            type: RecordingMaskType.covering,
          ),
        ]);

        await implementation.sessionReplaySetRecordingMask(recordingMask: recordingMask);
        expect(receivedMask?.recordingMaskList?.length, 1);
        expect(receivedMask?.recordingMaskList?.first.type, GeneratedRecordingMaskType.covering);
      });
    });

    group('Session State', () {
      test('should get session id', () async {
        mockApi.sessionStateGetIdHandler = () async => 'session-abc-123';
        expect(await implementation.sessionStateGetId(), 'session-abc-123');
      });

      test('should get session sampling rate', () async {
        mockApi.sessionStateGetSamplingRateHandler = () async => 0.75;
        expect(await implementation.sessionStateGetSamplingRate(), 0.75);
      });
    });

    group('User Tracking', () {
      test('should get user state tracking mode', () async {
        mockApi.userStateGetUserTrackingModeHandler = () async {
          return GeneratedUserTrackingMode.anonymousTracking;
        };

        final mode = await implementation.userStateGetUserTrackingMode();
        expect(mode, UserTrackingMode.anonymousTracking);
      });

      test('should get user preferences tracking mode', () async {
        mockApi.userPreferencesGetUserTrackingModeHandler = () async {
          return GeneratedUserTrackingMode.noTracking;
        };

        final mode = await implementation.userPreferencesGetUserTrackingMode();
        expect(mode, UserTrackingMode.noTracking);
      });

      test('should handle null user preferences tracking mode', () async {
        mockApi.userPreferencesGetUserTrackingModeHandler = () async => null;

        final mode = await implementation.userPreferencesGetUserTrackingMode();
        expect(mode, isNull);
      });

      test('should set user preferences tracking mode', () async {
        GeneratedUserTrackingMode? receivedMode;
        mockApi.userPreferencesSetUserTrackingModeHandler = (mode) async {
          receivedMode = mode;
        };

        await implementation.userPreferencesSetUserTrackingMode(
          userTrackingMode: UserTrackingMode.anonymousTracking,
        );
        expect(receivedMode, GeneratedUserTrackingMode.anonymousTracking);
      });
    });

    group('Global Attributes', () {
      test('should get attribute', () async {
        mockApi.globalAttributesGetHandler = (key) async {
          return GeneratedMutableAttributeString(value: 'value');
        };

        final result = await implementation.globalAttributesGet(key: 'key');
        expect(result, isA<MutableAttributeString>());
        expect((result as MutableAttributeString).value, 'value');
      });

      test('should get all attributes', () async {
        mockApi.globalAttributesGetAllHandler = () async {
          return GeneratedMutableAttributes(attributes: {
            'key1': GeneratedMutableAttributeString(value: 'value1'),
          });
        };

        final result = await implementation.globalAttributesGetAll();
        expect(result.attributes.length, 1);
      });

      test('should handle null when getting all attributes', () async {
        mockApi.globalAttributesGetAllHandler = () async => null;

        final result = await implementation.globalAttributesGetAll();
        expect(result.attributes, isEmpty);
      });

      test('should remove attribute', () async {
        String? removedKey;
        mockApi.globalAttributesRemoveHandler = (key) async {
          removedKey = key;
        };

        await implementation.globalAttributesRemove(key: 'test_key');
        expect(removedKey, 'test_key');
      });

      test('should remove all attributes', () async {
        bool called = false;
        mockApi.globalAttributesRemoveAllHandler = () async {
          called = true;
        };

        await implementation.globalAttributesRemoveAll();
        expect(called, true);
      });

      test('should check if contains attribute', () async {
        mockApi.globalAttributesContainsHandler = (key) async => true;
        expect(await implementation.globalAttributesContains(key: 'key'), true);
      });

      test('should set string attribute', () async {
        String? receivedKey;
        String? receivedValue;
        mockApi.globalAttributesSetStringHandler = (key, value) async {
          receivedKey = key;
          receivedValue = value;
        };

        await implementation.globalAttributesSetString(key: 'key', value: 'value');
        expect(receivedKey, 'key');
        expect(receivedValue, 'value');
      });

      test('should set int attribute', () async {
        String? receivedKey;
        int? receivedValue;
        mockApi.globalAttributesSetIntHandler = (key, value) async {
          receivedKey = key;
          receivedValue = value;
        };

        await implementation.globalAttributesSetInt(key: 'key', value: 42);
        expect(receivedKey, 'key');
        expect(receivedValue, 42);
      });

      test('should set double attribute', () async {
        String? receivedKey;
        double? receivedValue;
        mockApi.globalAttributesSetDoubleHandler = (key, value) async {
          receivedKey = key;
          receivedValue = value;
        };

        await implementation.globalAttributesSetDouble(key: 'key', value: 3.14);
        expect(receivedKey, 'key');
        expect(receivedValue, 3.14);
      });

      test('should set bool attribute', () async {
        String? receivedKey;
        bool? receivedValue;
        mockApi.globalAttributesSetBoolHandler = (key, value) async {
          receivedKey = key;
          receivedValue = value;
        };

        await implementation.globalAttributesSetBool(key: 'key', value: true);
        expect(receivedKey, 'key');
        expect(receivedValue, true);
      });

      test('should set string list attribute', () async {
        String? receivedKey;
        List<String>? receivedValue;
        mockApi.globalAttributesSetStringListHandler = (key, value) async {
          receivedKey = key;
          receivedValue = value;
        };

        await implementation.globalAttributesSetStringList(key: 'key', value: ['a', 'b']);
        expect(receivedKey, 'key');
        expect(receivedValue, ['a', 'b']);
      });

      test('should set int list attribute', () async {
        String? receivedKey;
        List<int>? receivedValue;
        mockApi.globalAttributesSetIntListHandler = (key, value) async {
          receivedKey = key;
          receivedValue = value;
        };

        await implementation.globalAttributesSetIntList(key: 'key', value: [1, 2, 3]);
        expect(receivedKey, 'key');
        expect(receivedValue, [1, 2, 3]);
      });

      test('should set double list attribute', () async {
        String? receivedKey;
        List<double>? receivedValue;
        mockApi.globalAttributesSetDoubleListHandler = (key, value) async {
          receivedKey = key;
          receivedValue = value;
        };

        await implementation.globalAttributesSetDoubleList(key: 'key', value: [1.1, 2.2]);
        expect(receivedKey, 'key');
        expect(receivedValue, [1.1, 2.2]);
      });

      test('should set bool list attribute', () async {
        String? receivedKey;
        List<bool>? receivedValue;
        mockApi.globalAttributesSetBoolListHandler = (key, value) async {
          receivedKey = key;
          receivedValue = value;
        };

        await implementation.globalAttributesSetBoolList(key: 'key', value: [true, false]);
        expect(receivedKey, 'key');
        expect(receivedValue, [true, false]);
      });

      test('should set all attributes', () async {
        GeneratedMutableAttributes? receivedAttributes;
        mockApi.globalAttributesSetAllHandler = (value) async {
          receivedAttributes = value;
        };

        final attributes = MutableAttributes(attributes: {
          'key': MutableAttributeString(value: 'value'),
        });

        await implementation.globalAttributesSetAll(attributes: attributes);
        expect(receivedAttributes?.attributes.length, 1);
      });
    });

    group('Custom Tracking', () {
      test('should track custom event', () async {
        String? receivedName;
        GeneratedMutableAttributes? receivedAttributes;
        mockApi.customTrackingTrackCustomEventHandler = (name, attributes) async {
          receivedName = name;
          receivedAttributes = attributes;
        };

        final attributes = MutableAttributes(attributes: {
          'key': MutableAttributeString(value: 'value'),
        });

        await implementation.customTrackingTrackCustomEvent(
          name: 'event_name',
          attributes: attributes,
        );

        expect(receivedName, 'event_name');
        expect(receivedAttributes?.attributes.length, 1);
      });

      test('should track workflow', () async {
        String? receivedWorkflowName;
        mockApi.customTrackingTrackWorkflowHandler = (workflowName) async {
          receivedWorkflowName = workflowName;
        };

        await implementation.customTrackingTrackWorkflow(workflowName: 'checkout');
        expect(receivedWorkflowName, 'checkout');
      });
    });

    group('Navigation', () {
      test('should track screen navigation', () async {
        String? receivedScreenName;
        mockApi.navigationTrackHandler = (screenName) async {
          receivedScreenName = screenName;
        };

        await implementation.navigationTrack(screenName: 'HomeScreen');
        expect(receivedScreenName, 'HomeScreen');
      });
    });
  });
}

