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
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Splunk OTel Flutter Package', () {
    test('should export SplunkRum class', () {
      expect(SplunkRum.instance, isNotNull);
      expect(SplunkRum.instance, isA<SplunkRum>());
    });

    test('should export AgentConfiguration class', () {
      final endpointConfig = EndpointConfiguration.forRum(
        realm: 'us0',
        rumAccessToken: 'test-token',
      );

      final config = AgentConfiguration(
        endpoint: endpointConfig,
        appName: 'TestApp',
        deploymentEnvironment: 'test',
      );

      expect(config, isA<AgentConfiguration>());
    });

    test('should export Status enum', () {
      expect(Status.running, isA<Status>());
      expect(Status.notInstalled, isA<Status>());
    });

    test('should export module configurations', () {
      expect(SlowRenderingModuleConfiguration(), isA<ModuleConfiguration>());
      expect(NavigationModuleConfiguration(), isA<ModuleConfiguration>());
      expect(CrashReportsModuleConfiguration(), isA<ModuleConfiguration>());
    });

    test('should export MutableAttributes', () {
      final attrs = const MutableAttributes();
      expect(attrs, isA<MutableAttributes>());
    });
  });
}
