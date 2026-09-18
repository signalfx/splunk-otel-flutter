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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter/src/rum_sdk_version.dart';

/// Reads the `version:` field from a `pubspec.yaml` without pulling in a
/// YAML parser dependency. The SDK forbids new dependencies, so we hand-parse
/// the single line we care about.
String? _readPubspecVersion(File pubspec) {
  final lines = pubspec.readAsLinesSync();
  for (final line in lines) {
    final match = RegExp(r'^version:\s*(\S+)\s*$').firstMatch(line);
    if (match != null) {
      return match.group(1);
    }
  }

  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('rumSdkFlutterVersion', () {
    test('should match the version in pubspec.yaml', () {
      // `flutter test` runs with the package root as the current directory.
      final pubspec = File('pubspec.yaml');
      expect(
        pubspec.existsSync(),
        isTrue,
        reason: 'Expected to find pubspec.yaml at ${pubspec.absolute.path}',
      );

      final pubspecVersion = _readPubspecVersion(pubspec);
      expect(
        pubspecVersion,
        isNotNull,
        reason: 'Could not find a `version:` line in pubspec.yaml',
      );

      expect(
        rumSdkFlutterVersion,
        equals(pubspecVersion),
        reason:
            'rumSdkFlutterVersion (lib/src/rum_sdk_version.dart) is out of '
            'sync with pubspec.yaml. Update both to the same value before '
            'releasing.',
      );
    });
  });
}
