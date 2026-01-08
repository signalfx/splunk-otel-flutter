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
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplunkOtelFlutter', () {
    test('should be a singleton', () {
      final instance1 = SplunkOtelFlutter.instance;
      final instance2 = SplunkOtelFlutter.instance;

      expect(instance1, same(instance2));
    });

    test('should expose session module', () {
      final instance = SplunkOtelFlutter.instance;
      expect(instance.session, isNotNull);
    });

    test('should expose state module', () {
      final instance = SplunkOtelFlutter.instance;
      expect(instance.state, isNotNull);
    });

    test('should expose user module', () {
      final instance = SplunkOtelFlutter.instance;
      expect(instance.user, isNotNull);
    });

    test('should expose sessionReplay module', () {
      final instance = SplunkOtelFlutter.instance;
      expect(instance.sessionReplay, isNotNull);
    });

    test('should expose globalAttributes module', () {
      final instance = SplunkOtelFlutter.instance;
      expect(instance.globalAttributes, isNotNull);
    });

    test('should expose customTracking module', () {
      final instance = SplunkOtelFlutter.instance;
      expect(instance.customTracking, isNotNull);
    });

    test('should expose navigation module', () {
      final instance = SplunkOtelFlutter.instance;
      expect(instance.navigation, isNotNull);
    });
  });

  group('AgentConfiguration', () {
    test('should create configuration with required parameters', () {
      final endpointConfig = EndpointConfiguration.forRum(
        realm: 'us0',
        rumAccessToken: 'test-token',
      );
      
      final config = AgentConfiguration(
        endpointConfiguration: endpointConfig,
        appName: 'TestApp',
        deploymentEnvironment: 'test',
      );

      expect(config.appName, equals('TestApp'));
      expect(config.deploymentEnvironment, equals('test'));
      expect(config.endpointConfiguration, equals(endpointConfig));
    });

    test('should create configuration with optional parameters', () {
      final endpointConfig = EndpointConfiguration.forRum(
        realm: 'us0',
        rumAccessToken: 'test-token',
      );
      
      final config = AgentConfiguration(
        endpointConfiguration: endpointConfig,
        appName: 'TestApp',
        deploymentEnvironment: 'production',
        appVersion: '1.0.0',
        enableDebugLogging: true,
      );

      expect(config.deploymentEnvironment, equals('production'));
      expect(config.appVersion, equals('1.0.0'));
      expect(config.enableDebugLogging, isTrue);
    });
  });

  group('EndpointConfiguration', () {
    test('should create endpoint configuration for RUM', () {
      final config = EndpointConfiguration.forRum(
        realm: 'us0',
        rumAccessToken: 'test-token',
      );

      expect(config.realm, equals('us0'));
      expect(config.rumAccessToken, equals('test-token'));
      expect(config.traceEndpoint, isNull);
      expect(config.sessionReplayEndpoint, isNull);
    });

    test('should create endpoint configuration for traces', () {
      final tracesUri = Uri.parse('https://traces.example.com');
      final config = EndpointConfiguration.forTraces(
        tracesEndpoint: tracesUri,
      );

      expect(config.traceEndpoint, equals(tracesUri));
      expect(config.realm, isNull);
      expect(config.sessionReplayEndpoint, isNull);
    });

    test('should create endpoint configuration for traces and session replay', () {
      final tracesUri = Uri.parse('https://traces.example.com');
      final replayUri = Uri.parse('https://replay.example.com');
      
      final config = EndpointConfiguration.forTracesAndSessionReplay(
        traceEndpoint: tracesUri,
        sessionReplayEndpoint: replayUri,
      );

      expect(config.traceEndpoint, equals(tracesUri));
      expect(config.sessionReplayEndpoint, equals(replayUri));
      expect(config.realm, isNull);
    });
  });

  group('ModuleConfiguration', () {
    test('SlowRenderingModuleConfiguration should be creatable', () {
      final config = SlowRenderingModuleConfiguration();
      expect(config, isNotNull);
    });

    test('NavigationModuleConfiguration should be creatable', () {
      final config = NavigationModuleConfiguration();
      expect(config, isNotNull);
    });

    test('CrashReportsModuleConfiguration should be creatable', () {
      final config = CrashReportsModuleConfiguration();
      expect(config, isNotNull);
    });

    test('InteractionsModuleConfiguration should be creatable', () {
      final config = InteractionsModuleConfiguration();
      expect(config, isNotNull);
    });

    test('NetworkMonitorModuleConfiguration should be creatable', () {
      final config = NetworkMonitorModuleConfiguration();
      expect(config, isNotNull);
    });

    test('AnrModuleConfiguration should be creatable', () {
      final config = AnrModuleConfiguration();
      expect(config, isNotNull);
      expect(config.isEnabled, isTrue);
    });

    test('HttpUrlModuleConfiguration should be creatable', () {
      final config = HttpUrlModuleConfiguration();
      expect(config, isNotNull);
    });

    test('OkHttp3AutoModuleConfiguration should be creatable', () {
      final config = OkHttp3AutoModuleConfiguration();
      expect(config, isNotNull);
    });

    test('NetworkInstrumentationModuleConfiguration should be creatable', () {
      final config = NetworkInstrumentationModuleConfiguration();
      expect(config, isNotNull);
    });
  });

  group('MutableAttributes', () {
    test('should create empty attributes', () {
      final attributes = const MutableAttributes();
      expect(attributes.attributes, isEmpty);
    });

    test('should create attributes from map', () {
      final attributes = MutableAttributes(attributes: {
        'key1': MutableAttributeString(value: 'value1'),
        'key2': MutableAttributeInt(value: 42),
      });
      
      expect(attributes.attributes.length, equals(2));
      expect((attributes.attributes['key1'] as MutableAttributeString).value, equals('value1'));
      expect((attributes.attributes['key2'] as MutableAttributeInt).value, equals(42));
    });
  });

  group('Status', () {
    test('should have expected enum values', () {
      expect(Status.values.length, equals(6));
      expect(Status.values, contains(Status.running));
      expect(Status.values, contains(Status.notInstalled));
      expect(Status.values, contains(Status.subProcess));
      expect(Status.values, contains(Status.sampledOut));
      expect(Status.values, contains(Status.unsupportedPlatform));
      expect(Status.values, contains(Status.unsupportedOsVersion));
    });
  });

  group('SessionReplay', () {
    test('SessionReplayStatus should have expected values', () {
      expect(SessionReplayStatus.values.length, equals(6));
      expect(SessionReplayStatus.values, contains(SessionReplayStatus.isRecording));
      expect(SessionReplayStatus.values, contains(SessionReplayStatus.notStarted));
      expect(SessionReplayStatus.values, contains(SessionReplayStatus.stopped));
      expect(SessionReplayStatus.values, contains(SessionReplayStatus.belowMinSdkVersion));
      expect(SessionReplayStatus.values, contains(SessionReplayStatus.storageLimitReached));
      expect(SessionReplayStatus.values, contains(SessionReplayStatus.internalError));
    });

    test('RenderingMode should have expected values', () {
      expect(RenderingMode.values.length, equals(2));
      expect(RenderingMode.values, contains(RenderingMode.native));
      expect(RenderingMode.values, contains(RenderingMode.wireframeOnly));
    });

    test('RecordingMaskType should have expected values', () {
      expect(RecordingMaskType.values.length, equals(2));
      expect(RecordingMaskType.values, contains(RecordingMaskType.erasing));
      expect(RecordingMaskType.values, contains(RecordingMaskType.covering));
    });

    test('RecordingMaskElement should be creatable', () {
      final rect = const Rect.fromLTWH(10, 20, 100, 50);
      final element = RecordingMaskElement(
        rect: rect,
        type: RecordingMaskType.erasing,
      );

      expect(element.type, equals(RecordingMaskType.erasing));
      expect(element.rect, equals(rect));
    });

    test('RecordingMaskList should be creatable', () {
      final rect = const Rect.fromLTWH(0, 0, 50, 50);
      final maskList = RecordingMaskList(elements: [
        RecordingMaskElement(
          rect: rect,
          type: RecordingMaskType.covering,
        ),
      ]);

      expect(maskList.elements.length, equals(1));
      expect(maskList.elements[0].type, equals(RecordingMaskType.covering));
      expect(maskList.elements[0].rect, equals(rect));
    });
  });
}

