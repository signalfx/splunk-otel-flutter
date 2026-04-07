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
import 'package:splunk_otel_flutter_platform_interface/src/model/session_replay.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

void main() {
  group('SessionReplayStatus', () {
    test('should have all expected enum values', () {
      final allStatuses = SessionReplayStatus.values;

      expect(allStatuses.length, 7);
      expect(allStatuses, contains(SessionReplayStatus.isRecording));
      expect(allStatuses, contains(SessionReplayStatus.notStarted));
      expect(allStatuses, contains(SessionReplayStatus.stopped));
      expect(allStatuses, contains(SessionReplayStatus.belowMinSdkVersion));
      expect(allStatuses, contains(SessionReplayStatus.storageLimitReached));
      expect(allStatuses, contains(SessionReplayStatus.internalError));
      expect(allStatuses, contains(SessionReplayStatus.disabledBySampling));
    });

    test('should convert to GeneratedSessionReplayStatus correctly', () {
      final mappings = {
        SessionReplayStatus.isRecording: GeneratedSessionReplayStatus.isRecording,
        SessionReplayStatus.notStarted: GeneratedSessionReplayStatus.notStarted,
        SessionReplayStatus.stopped: GeneratedSessionReplayStatus.stopped,
        SessionReplayStatus.belowMinSdkVersion: GeneratedSessionReplayStatus.belowMinSdkVersion,
        SessionReplayStatus.storageLimitReached: GeneratedSessionReplayStatus.storageLimitReached,
        SessionReplayStatus.internalError: GeneratedSessionReplayStatus.internalError,
        SessionReplayStatus.disabledBySampling: GeneratedSessionReplayStatus.disabledBySampling,
      };

      for (final entry in mappings.entries) {
        final generated = entry.key.toGeneratedSessionReplayStatus();
        expect(generated, entry.value);
      }
    });

    test('should convert from GeneratedSessionReplayStatus correctly', () {
      final mappings = {
        GeneratedSessionReplayStatus.isRecording: SessionReplayStatus.isRecording,
        GeneratedSessionReplayStatus.notStarted: SessionReplayStatus.notStarted,
        GeneratedSessionReplayStatus.stopped: SessionReplayStatus.stopped,
        GeneratedSessionReplayStatus.belowMinSdkVersion: SessionReplayStatus.belowMinSdkVersion,
        GeneratedSessionReplayStatus.storageLimitReached: SessionReplayStatus.storageLimitReached,
        GeneratedSessionReplayStatus.internalError: SessionReplayStatus.internalError,
        GeneratedSessionReplayStatus.disabledBySampling: SessionReplayStatus.disabledBySampling,
      };

      for (final entry in mappings.entries) {
        final status = entry.key.toSessionReplayStatus();
        expect(status, entry.value);
      }
    });
  });

  group('RecordingMaskType', () {
    test('should have all expected enum values', () {
      final allTypes = RecordingMaskType.values;

      expect(allTypes.length, 2);
      expect(allTypes, contains(RecordingMaskType.erasing));
      expect(allTypes, contains(RecordingMaskType.covering));
    });

    test('should convert to GeneratedRecordingMaskType correctly', () {
      expect(
        RecordingMaskType.erasing.toGeneratedRecordingMaskType(),
        GeneratedRecordingMaskType.erasing,
      );
      expect(
        RecordingMaskType.covering.toGeneratedRecordingMaskType(),
        GeneratedRecordingMaskType.covering,
      );
    });

    test('should convert from GeneratedRecordingMaskType correctly', () {
      expect(
        GeneratedRecordingMaskType.erasing.toRecordingMaskType(),
        RecordingMaskType.erasing,
      );
      expect(
        GeneratedRecordingMaskType.covering.toRecordingMaskType(),
        RecordingMaskType.covering,
      );
    });
  });

  group('Rect Conversion', () {
    test('should convert Rect to GeneratedRect', () {
      final rect = const Rect.fromLTWH(10.0, 20.0, 100.0, 200.0);
      final generated = rect.toGeneratedRect();

      expect(generated.left, 10.0);
      expect(generated.top, 20.0);
      expect(generated.width, 100.0);
      expect(generated.height, 200.0);
    });

    test('should convert GeneratedRect to Rect', () {
      final generated = GeneratedRect(left: 10.0, top: 20.0, width: 100.0, height: 200.0);
      final rect = generated.toRect();

      expect(rect.left, 10.0);
      expect(rect.top, 20.0);
      expect(rect.width, 100.0);
      expect(rect.height, 200.0);
    });

    test('should handle zero dimensions', () {
      final rect = const Rect.fromLTWH(0, 0, 0, 0);
      final generated = rect.toGeneratedRect();
      final converted = generated.toRect();

      expect(converted.left, 0);
      expect(converted.top, 0);
      expect(converted.width, 0);
      expect(converted.height, 0);
    });

    test('should handle negative positions', () {
      final rect = const Rect.fromLTWH(-10.0, -20.0, 100.0, 200.0);
      final generated = rect.toGeneratedRect();
      final converted = generated.toRect();

      expect(converted.left, -10.0);
      expect(converted.top, -20.0);
      expect(converted.width, 100.0);
      expect(converted.height, 200.0);
    });

    test('should handle large dimensions', () {
      final rect = const Rect.fromLTWH(0, 0, 10000.0, 10000.0);
      final generated = rect.toGeneratedRect();
      final converted = generated.toRect();

      expect(converted.width, 10000.0);
      expect(converted.height, 10000.0);
    });
  });

  group('RecordingMaskElement', () {
    test('should create with rect and type', () {
      final element = RecordingMaskElement(
        rect: const Rect.fromLTWH(10, 20, 100, 200),
        type: RecordingMaskType.erasing,
      );

      expect(element.rect, const Rect.fromLTWH(10, 20, 100, 200));
      expect(element.type, RecordingMaskType.erasing);
    });

    test('should convert to GeneratedRecordingMaskElement', () {
      final element = RecordingMaskElement(
        rect: const Rect.fromLTWH(10, 20, 100, 200),
        type: RecordingMaskType.covering,
      );

      final generated = element.toGeneratedRecordingMaskElement();

      expect(generated.rect.left, 10);
      expect(generated.rect.top, 20);
      expect(generated.rect.width, 100);
      expect(generated.rect.height, 200);
      expect(generated.type, GeneratedRecordingMaskType.covering);
    });

    test('should convert from GeneratedRecordingMaskElement', () {
      final generated = GeneratedRecordingMaskElement(
        rect: GeneratedRect(left: 10, top: 20, width: 100, height: 200),
        type: GeneratedRecordingMaskType.erasing,
      );

      final element = generated.toRecordingMask();

      expect(element.rect.left, 10);
      expect(element.rect.top, 20);
      expect(element.rect.width, 100);
      expect(element.rect.height, 200);
      expect(element.type, RecordingMaskType.erasing);
    });
  });

  group('RecordingMaskList', () {
    test('should create with empty list', () {
      final list = RecordingMaskList(elements: []);

      expect(list.elements, isEmpty);
    });

    test('should create with single element', () {
      final list = RecordingMaskList(elements: [
        RecordingMaskElement(
          rect: const Rect.fromLTWH(0, 0, 100, 100),
          type: RecordingMaskType.erasing,
        ),
      ]);

      expect(list.elements.length, 1);
      expect(list.elements[0].type, RecordingMaskType.erasing);
    });

    test('should create with multiple elements', () {
      final list = RecordingMaskList(elements: [
        RecordingMaskElement(
          rect: const Rect.fromLTWH(0, 0, 100, 100),
          type: RecordingMaskType.erasing,
        ),
        RecordingMaskElement(
          rect: const Rect.fromLTWH(100, 100, 200, 200),
          type: RecordingMaskType.covering,
        ),
      ]);

      expect(list.elements.length, 2);
      expect(list.elements[0].type, RecordingMaskType.erasing);
      expect(list.elements[1].type, RecordingMaskType.covering);
    });

    test('should convert to GeneratedRecordingMaskList', () {
      final list = RecordingMaskList(elements: [
        RecordingMaskElement(
          rect: const Rect.fromLTWH(0, 0, 100, 100),
          type: RecordingMaskType.erasing,
        ),
        RecordingMaskElement(
          rect: const Rect.fromLTWH(100, 100, 200, 200),
          type: RecordingMaskType.covering,
        ),
      ]);

      final generated = list.toGeneratedRecordingMaskList();

      expect(generated.recordingMaskList?.length, 2);
      expect(generated.recordingMaskList?[0].type, GeneratedRecordingMaskType.erasing);
      expect(generated.recordingMaskList?[1].type, GeneratedRecordingMaskType.covering);
    });

    test('should convert from GeneratedRecordingMaskList', () {
      final generated = GeneratedRecordingMaskList(recordingMaskList: [
        GeneratedRecordingMaskElement(
          rect: GeneratedRect(left: 0, top: 0, width: 100, height: 100),
          type: GeneratedRecordingMaskType.erasing,
        ),
        GeneratedRecordingMaskElement(
          rect: GeneratedRect(left: 100, top: 100, width: 200, height: 200),
          type: GeneratedRecordingMaskType.covering,
        ),
      ]);

      final list = generated.toRecordingMaskList();

      expect(list.elements.length, 2);
      expect(list.elements[0].type, RecordingMaskType.erasing);
      expect(list.elements[1].type, RecordingMaskType.covering);
    });

    test('should handle null recordingMaskList in GeneratedRecordingMaskList', () {
      final generated = GeneratedRecordingMaskList(recordingMaskList: null);
      final list = generated.toRecordingMaskList();

      expect(list.elements, isEmpty);
    });

    test('should handle empty list conversion', () {
      final list = RecordingMaskList(elements: []);
      final generated = list.toGeneratedRecordingMaskList();
      final converted = generated.toRecordingMaskList();

      expect(converted.elements, isEmpty);
    });
  });

  group('Round-trip Conversion', () {
    test('should handle round-trip conversion for RecordingMaskElement', () {
      final original = RecordingMaskElement(
        rect: const Rect.fromLTWH(50, 100, 150, 250),
        type: RecordingMaskType.erasing,
      );

      final generated = original.toGeneratedRecordingMaskElement();
      final converted = generated.toRecordingMask();

      expect(converted.rect, original.rect);
      expect(converted.type, original.type);
    });

    test('should handle round-trip conversion for RecordingMaskList', () {
      final original = RecordingMaskList(elements: [
        RecordingMaskElement(
          rect: const Rect.fromLTWH(0, 0, 100, 100),
          type: RecordingMaskType.erasing,
        ),
        RecordingMaskElement(
          rect: const Rect.fromLTWH(100, 100, 200, 200),
          type: RecordingMaskType.covering,
        ),
      ]);

      final generated = original.toGeneratedRecordingMaskList();
      final converted = generated.toRecordingMaskList();

      expect(converted.elements.length, original.elements.length);
      for (int i = 0; i < converted.elements.length; i++) {
        expect(converted.elements[i].rect, original.elements[i].rect);
        expect(converted.elements[i].type, original.elements[i].type);
      }
    });
  });

  group('Complex Scenarios', () {
    test('should handle mixed masking types', () {
      final list = RecordingMaskList(elements: [
        RecordingMaskElement(
          rect: const Rect.fromLTWH(0, 0, 50, 50),
          type: RecordingMaskType.erasing,
        ),
        RecordingMaskElement(
          rect: const Rect.fromLTWH(60, 60, 50, 50),
          type: RecordingMaskType.covering,
        ),
        RecordingMaskElement(
          rect: const Rect.fromLTWH(120, 120, 50, 50),
          type: RecordingMaskType.erasing,
        ),
      ]);

      final generated = list.toGeneratedRecordingMaskList();
      final converted = generated.toRecordingMaskList();

      expect(converted.elements[0].type, RecordingMaskType.erasing);
      expect(converted.elements[1].type, RecordingMaskType.covering);
      expect(converted.elements[2].type, RecordingMaskType.erasing);
    });

    test('should handle overlapping masks', () {
      final list = RecordingMaskList(elements: [
        RecordingMaskElement(
          rect: const Rect.fromLTWH(0, 0, 100, 100),
          type: RecordingMaskType.erasing,
        ),
        RecordingMaskElement(
          rect: const Rect.fromLTWH(50, 50, 100, 100),
          type: RecordingMaskType.covering,
        ),
      ]);

      final generated = list.toGeneratedRecordingMaskList();
      final converted = generated.toRecordingMaskList();

      // Both masks should be preserved
      expect(converted.elements.length, 2);
    });
  });
}



