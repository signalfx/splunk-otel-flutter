/*
 * Copyright 2026 Splunk Inc.
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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter/src/rum_sdk_version.dart';
import 'package:splunk_otel_flutter/src/rum_telemetry_metadata.dart';
import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

AgentConfiguration _baseConfig({MutableAttributes? globalAttributes}) {
  return AgentConfiguration(
    endpointConfiguration: EndpointConfiguration.forRum(
      realm: 'us0',
      rumAccessToken: 'test-token',
    ),
    appName: 'TestApp',
    deploymentEnvironment: 'test',
    globalAttributes: globalAttributes,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('applyRumTelemetryMetadata', () {
    group('rum.sdk.flutter.version', () {
      test('should add SDK version from rumSdkFlutterVersion constant', () {
        final config = _baseConfig();

        final enriched = mergeRumTelemetryMetadataForTesting(config);

        final sdkVersion = enriched.globalAttributes?.attributes[
            'rum.sdk.flutter.version'] as MutableAttributeString;
        expect(sdkVersion.value, equals(rumSdkFlutterVersion));
      });

      test('should override user-provided rum.sdk.flutter.version', () {
        final config = _baseConfig(
          globalAttributes: MutableAttributes(attributes: {
            'rum.sdk.flutter.version':
                MutableAttributeString(value: 'user-override'),
          }),
        );

        final enriched = mergeRumTelemetryMetadataForTesting(config);

        final sdkVersion = enriched.globalAttributes?.attributes[
            'rum.sdk.flutter.version'] as MutableAttributeString;
        expect(sdkVersion.value, equals(rumSdkFlutterVersion));
      });
    });

    group('splunk.app.framework.flutter.version', () {
      test('should use FlutterVersion.version or fall back to unknown', () {
        final config = _baseConfig();

        final enriched = mergeRumTelemetryMetadataForTesting(config);

        final frameworkVersion = enriched.globalAttributes?.attributes[
                'splunk.app.framework.flutter.version']
            as MutableAttributeString;
        final expected = FlutterVersion.version ?? 'unknown';
        expect(frameworkVersion.value, equals(expected));
      });

      test('should use provided framework version override', () {
        final config = _baseConfig();

        final enriched = mergeRumTelemetryMetadataForTesting(
          config,
          flutterFrameworkVersion: '3.32.0',
        );

        final frameworkVersion = enriched.globalAttributes?.attributes[
                'splunk.app.framework.flutter.version']
            as MutableAttributeString;
        expect(frameworkVersion.value, equals('3.32.0'));
      });

      test(
          'should override user-provided splunk.app.framework.flutter.version',
          () {
        final config = _baseConfig(
          globalAttributes: MutableAttributes(attributes: {
            'splunk.app.framework.flutter.version':
                MutableAttributeString(value: 'user-override'),
          }),
        );

        final enriched = mergeRumTelemetryMetadataForTesting(config);

        final frameworkVersion = enriched.globalAttributes?.attributes[
                'splunk.app.framework.flutter.version']
            as MutableAttributeString;
        final expected = FlutterVersion.version ?? 'unknown';
        expect(frameworkVersion.value, equals(expected));
      });
    });

    group('existing global attributes', () {
      test('should preserve user-provided global attributes', () {
        final config = _baseConfig(
          globalAttributes: MutableAttributes(attributes: {
            'user.tier': MutableAttributeString(value: 'premium'),
            'app.build': MutableAttributeInt(value: 42),
          }),
        );

        final enriched = mergeRumTelemetryMetadataForTesting(config);

        final attributes = enriched.globalAttributes!.attributes;
        expect(attributes.length, equals(4));

        final userTier =
            attributes['user.tier'] as MutableAttributeString;
        expect(userTier.value, equals('premium'));

        final appBuild = attributes['app.build'] as MutableAttributeInt;
        expect(appBuild.value, equals(42));
      });

      test('should handle null global attributes', () {
        final config = _baseConfig();

        final enriched = mergeRumTelemetryMetadataForTesting(config);

        final attributes = enriched.globalAttributes!.attributes;
        expect(attributes.length, equals(2));
        expect(
          attributes.containsKey('splunk.app.framework.flutter.version'),
          isTrue,
        );
        expect(
          attributes.containsKey('rum.sdk.flutter.version'),
          isTrue,
        );
      });
    });

    group('agent configuration passthrough', () {
      test('should preserve all other configuration fields', () {
        final config = AgentConfiguration(
          endpointConfiguration: EndpointConfiguration.forRum(
            realm: 'eu0',
            rumAccessToken: 'my-token',
          ),
          appName: 'MyApp',
          deploymentEnvironment: 'staging',
          appVersion: '2.0.0',
          enableDebugLogging: true,
          instrumentedProcessName: 'my_process',
          deferredUntilForeground: true,
          user: const UserConfiguration(
            trackingMode: UserTrackingMode.anonymousTracking,
          ),
          session: SessionConfiguration(samplingRate: 0.5),
        );

        final enriched = mergeRumTelemetryMetadataForTesting(config);

        expect(enriched.appName, equals('MyApp'));
        expect(enriched.deploymentEnvironment, equals('staging'));
        expect(enriched.appVersion, equals('2.0.0'));
        expect(enriched.enableDebugLogging, isTrue);
        expect(enriched.instrumentedProcessName, equals('my_process'));
        expect(enriched.deferredUntilForeground, isTrue);
        expect(
          enriched.user.trackingMode,
          equals(UserTrackingMode.anonymousTracking),
        );
        expect(enriched.session.samplingRate, equals(0.5));
        expect(enriched.endpointConfiguration!.realm, equals('eu0'));
        expect(
          enriched.endpointConfiguration!.rumAccessToken,
          equals('my-token'),
        );
      });
    });
  });

  group('rumSdkFlutterVersion', () {
    test('should be a non-empty semver string', () {
      expect(rumSdkFlutterVersion, isNotEmpty);
      expect(
        RegExp(r'^\d+\.\d+\.\d+').hasMatch(rumSdkFlutterVersion),
        isTrue,
      );
    });
  });
}
