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
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplunkSessionReplay', () {
    test('should be accessible via singleton', () {
      final sessionReplay = SplunkSessionReplay.instance;
      expect(sessionReplay, isNotNull);
    });

    test('singleton should always return the same instance', () {
      final first = SplunkSessionReplay.instance;
      final second = SplunkSessionReplay.instance;
      expect(identical(first, second), isTrue);
    });

    test('should expose start', () {
      expect(SplunkSessionReplay.instance.start, isA<Function>());
    });

    test('should expose stop', () {
      expect(SplunkSessionReplay.instance.stop, isA<Function>());
    });

    test('should expose getStatus', () {
      expect(SplunkSessionReplay.instance.getStatus, isA<Function>());
    });

    test('should expose getRecordingMask', () {
      expect(SplunkSessionReplay.instance.getRecordingMask, isA<Function>());
    });

    test('should expose setRecordingMask', () {
      expect(SplunkSessionReplay.instance.setRecordingMask, isA<Function>());
    });
  });
}
