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

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/dynamic_property.dart';

const Color _red = Color(0xFFFF0000);

/// Stands in for a private render object that declares the member.
class _Declares {
  Color get color => _red;
}

/// Stands in for a Flutter version that removed the member.
class _Omits {}

/// Stands in for a Flutter version that repurposed the member.
class _ChangesType {
  String get color => 'not a colour';
}

void main() {
  group('readUnnameable', () {
    test('should return the value when the member is present', () {
      final Object subject = _Declares();

      expect(
        readUnnameable<Color>(() => (subject as dynamic).color as Color),
        _red,
      );
    });

    test('should return null when the member is absent', () {
      // What a future Flutter release removing the member would look like.
      final Object subject = _Omits();

      expect(
        readUnnameable<Color>(() => (subject as dynamic).color as Color),
        isNull,
      );
    });

    test('should return null when the member has an unexpected type', () {
      final Object subject = _ChangesType();

      expect(
        readUnnameable<Color>(() => (subject as dynamic).color as Color),
        isNull,
      );
    });

    test('should not swallow unrelated failures', () {
      // Degrading softly is meant to cover the member going away, not to hide
      // a genuine bug inside the read.
      expect(
        () => readUnnameable<Color>(() => throw const FormatException('boom')),
        throwsFormatException,
      );
    });
  });
}
