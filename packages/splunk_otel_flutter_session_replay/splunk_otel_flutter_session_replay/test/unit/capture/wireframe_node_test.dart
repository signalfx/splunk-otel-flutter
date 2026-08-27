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
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

void main() {
  group('WireframeSkeleton', () {
    test('should serialize geometry as doubles', () {
      const skeleton = WireframeSkeleton(
        rect: Rect.fromLTWH(1, 2, 3, 4),
        color: Color(0xFF102030),
      );

      final json = skeleton.toJson();

      // The native parser casts these with `as Double`, so an int would throw
      // on the Kotlin side.
      expect(json['left'], isA<double>());
      expect(json['top'], isA<double>());
      expect(json['width'], isA<double>());
      expect(json['height'], isA<double>());
      expect(json['left'], 1.0);
      expect(json['top'], 2.0);
      expect(json['width'], 3.0);
      expect(json['height'], 4.0);
    });

    test('should serialize color as RGB hex', () {
      const skeleton = WireframeSkeleton(
        rect: Rect.zero,
        color: Color(0xFF102030),
      );

      expect(skeleton.toJson()['color'], '#102030');
    });

    test('should omit opacity when fully opaque', () {
      const skeleton = WireframeSkeleton(
        rect: Rect.zero,
        color: Color(0xFF000000),
      );

      expect(skeleton.toJson().containsKey('opacity'), isFalse);
    });

    test('should fold color alpha into opacity', () {
      const skeleton = WireframeSkeleton(
        rect: Rect.zero,
        color: Color(0x80FF0000),
      );

      // The wire format carries no alpha channel, so a translucent color would
      // otherwise be replayed as fully opaque.
      expect(skeleton.toJson()['color'], '#ff0000');
      expect(skeleton.toJson()['opacity'] as double, closeTo(0.5, 0.01));
    });

    test('should combine inherited opacity with color alpha', () {
      const skeleton = WireframeSkeleton(
        rect: Rect.zero,
        color: Color(0x80FF0000),
        opacity: 0.5,
      );

      expect(skeleton.toJson()['opacity'] as double, closeTo(0.25, 0.01));
    });

    test('should omit isText when not text', () {
      const skeleton = WireframeSkeleton(
        rect: Rect.zero,
        color: Color(0xFF000000),
      );

      expect(skeleton.toJson().containsKey('isText'), isFalse);
    });

    test('should include isText when text', () {
      const skeleton = WireframeSkeleton(
        rect: Rect.zero,
        color: Color(0xFF000000),
        isText: true,
      );

      expect(skeleton.toJson()['isText'], isTrue);
    });
  });

  group('WireframeNode', () {
    test('should serialize required fields', () {
      final node = WireframeNode(
        id: '7',
        type: 'Container',
        rect: const Rect.fromLTWH(10, 20, 30, 40),
      );

      final json = node.toJson();

      expect(json['id'], '7');
      expect(json['type'], 'Container');
      expect(json['left'], 10.0);
      expect(json['top'], 20.0);
      expect(json['width'], 30.0);
      expect(json['height'], 40.0);
    });

    test('should omit empty collections and default flags', () {
      final node = WireframeNode(id: '1', type: 'X', rect: Rect.zero);

      final json = node.toJson();

      expect(json.containsKey('children'), isFalse);
      expect(json.containsKey('skeletons'), isFalse);
      expect(json.containsKey('opacity'), isFalse);
      expect(json.containsKey('isSensitive'), isFalse);
      expect(json.containsKey('nativeViewId'), isFalse);
    });

    test('should include optional fields when set', () {
      final node = WireframeNode(
        id: '1',
        type: 'X',
        rect: Rect.zero,
        opacity: 0.5,
        isSensitive: true,
        nativeViewId: 42,
      );

      final json = node.toJson();

      expect(json['opacity'], 0.5);
      expect(json['isSensitive'], isTrue);
      // The native parser casts this with `as Int`.
      expect(json['nativeViewId'], isA<int>());
      expect(json['nativeViewId'], 42);
    });

    test('should serialize children recursively in insertion order', () {
      final root = WireframeNode(id: '1', type: 'Root', rect: Rect.zero)
        ..addChild(WireframeNode(id: '2', type: 'A', rect: Rect.zero))
        ..addChild(WireframeNode(id: '3', type: 'B', rect: Rect.zero));

      final children = root.toJson()['children']! as List<Object?>;

      expect(children, hasLength(2));
      expect((children[0]! as Map<String, Object?>)['type'], 'A');
      expect((children[1]! as Map<String, Object?>)['type'], 'B');
    });

    test('should count nodes in the subtree', () {
      final root = WireframeNode(id: '1', type: 'Root', rect: Rect.zero)
        ..addChild(
          WireframeNode(id: '2', type: 'A', rect: Rect.zero)
            ..addChild(WireframeNode(id: '3', type: 'A1', rect: Rect.zero)),
        )
        ..addChild(WireframeNode(id: '4', type: 'B', rect: Rect.zero));

      expect(root.subtreeNodeCount, 4);
    });
  });
}
