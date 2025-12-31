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
import 'package:splunk_otel_flutter_session_replay_platform_interface/platform_interface/splunk_otel_flutter_session_replay_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplunkOtelFlutterSessionReplayPlatformInterface', () {
    test('should have a default instance', () {
      expect(SplunkOtelFlutterSessionReplayPlatformInterface.instance, isNotNull);
    });

    test('instance should be of correct type', () {
      expect(
        SplunkOtelFlutterSessionReplayPlatformInterface.instance,
        isA<SplunkOtelFlutterSessionReplayPlatformInterface>(),
      );
    });
  });
}