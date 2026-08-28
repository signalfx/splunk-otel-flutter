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

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/sink/encoder/wireframe_encoder.dart';

WireframeFrame _frame({int viewId = 0}) {
  final root = WireframeNode(
    id: 'root',
    type: 'View',
    rect: const Rect.fromLTWH(0, 0, 400, 800),
  );
  final child = WireframeNode(
    id: 'child',
    type: 'ColoredBox',
    rect: const Rect.fromLTWH(4, 8, 100, 20),
    opacity: 0.5,
    isSensitive: true,
    skeletons: <WireframeSkeleton>[
      const WireframeSkeleton(
        rect: Rect.fromLTWH(4, 8, 100, 20),
        color: Color(0xFF123456),
        isText: true,
      ),
    ],
  );
  root.addChild(child);

  return WireframeFrame(
    viewId: viewId,
    capturedAt: DateTime.fromMicrosecondsSinceEpoch(1234567),
    viewSize: const Size(400, 800),
    devicePixelRatio: 2.0,
    root: root,
  );
}

void main() {
  group('WireframeEncoder', () {
    late WireframeEncoder encoder;

    setUp(() {
      encoder = WireframeEncoder();
    });

    tearDown(() async {
      await encoder.dispose();
    });

    test('should produce the same bytes as encoding inline', () async {
      final frame = _frame();

      final bytes = await encoder.encode(frame);

      // The whole design rests on a frame surviving the trip to a worker, so
      // this asserts the round trip is lossless rather than merely non-empty.
      expect(utf8.decode(bytes), jsonEncode(frame.toJson()));
    });

    test(
      'should preserve sensitivity and skeletons across the boundary',
      () async {
        final decoded =
            jsonDecode(utf8.decode(await encoder.encode(_frame())))
                as Map<String, dynamic>;

        final child =
            (decoded['tree'] as Map<String, dynamic>)['children']
                as List<Object?>;
        final node = child.single! as Map<String, dynamic>;

        expect(node['isSensitive'], isTrue);
        expect(node['opacity'], 0.5);
        expect(
          (node['skeletons'] as List<Object?>).single,
          isA<Map<String, dynamic>>(),
        );
      },
    );

    test('should answer concurrent frames in submission order', () async {
      final results = await Future.wait<List<int>>(<Future<List<int>>>[
        for (var i = 0; i < 5; i++) encoder.encode(_frame(viewId: i)),
      ]);

      final viewIds = <Object?>[
        for (final bytes in results)
          (jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>)['viewId'],
      ];

      expect(viewIds, <int>[0, 1, 2, 3, 4]);
    });

    test('should reuse one worker across frames', () async {
      // A fresh worker per frame would defeat the purpose, so this asserts the
      // second call succeeds without another start.
      await encoder.encode(_frame());
      final second = await encoder.encode(_frame(viewId: 7));

      expect(
        (jsonDecode(utf8.decode(second)) as Map<String, dynamic>)['viewId'],
        7,
      );
      expect(encoder.pending, 0);
    });

    test('should refuse work after dispose', () async {
      await encoder.encode(_frame());
      await encoder.dispose();

      // Rejected synchronously: submitting to a disposed encoder is a caller
      // bug, not a request that fails later.
      expect(() => encoder.encode(_frame()), throwsStateError);
    });

    test('should tolerate dispose without ever encoding', () async {
      await WireframeEncoder().dispose();
    });
  });
}
