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

import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter_platform_interface/src/implementation/splunk_otel_flutter_platform_implementation.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/mutable_attributes.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

import '../mock_splunk_otel_flutter_platform_interface_host_api.dart';
import '../pigeon/test_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation', () {
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

    test('should track screen navigation', () async {
      String? receivedScreenName;
      mockApi.navigationTrackHandler = (screenName, attributes) async {
        receivedScreenName = screenName;
      };

      await implementation.navigationTrack(
        screenName: 'HomeScreen',
        attributes: const MutableAttributes(),
      );

      expect(receivedScreenName, 'HomeScreen');
    });

    test('should forward custom attributes', () async {
      GeneratedMutableAttributes? receivedAttributes;
      mockApi.navigationTrackHandler = (name, attributes) async {
        receivedAttributes = attributes;
      };

      await implementation.navigationTrack(
        screenName: 'Details',
        attributes: MutableAttributes(
          attributes: {'section': MutableAttributeString(value: 'shoes')},
        ),
      );

      expect(receivedAttributes, isNotNull);
      expect(
        receivedAttributes!.attributes['section'],
        isA<GeneratedMutableAttributeString>(),
      );
    });

    test(
      'should forward null attributes as null (no attributes set)',
      () async {
        var called = false;
        GeneratedMutableAttributes? receivedAttributes;
        mockApi.navigationTrackHandler = (name, attributes) async {
          called = true;
          receivedAttributes = attributes;
        };

        await implementation.navigationTrack(screenName: 'Home');

        expect(called, true);
        expect(receivedAttributes, isNull);
      },
    );
  });
}
