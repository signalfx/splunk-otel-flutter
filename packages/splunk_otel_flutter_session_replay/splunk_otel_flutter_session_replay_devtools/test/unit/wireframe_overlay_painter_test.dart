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
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay_devtools/splunk_otel_flutter_session_replay_devtools.dart';

/// Captures `drawRect` calls so tests can assert on what was painted.
///
/// [Canvas] has a wide surface that this does not need, so everything other
/// than `drawRect` is absorbed by [noSuchMethod].
class _RecordingCanvas implements Canvas {
  final List<(Rect, Paint)> rects = <(Rect, Paint)>[];

  @override
  void drawRect(Rect rect, Paint paint) => rects.add((rect, paint));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

WireframeFrame _frameOf(WireframeNode root) => WireframeFrame(
  viewId: 0,
  capturedAt: DateTime.utc(2026),
  viewSize: const Size(100, 100),
  devicePixelRatio: 1,
  root: root,
);

void main() {
  group('WireframeOverlayPainter', () {
    const size = Size(100, 100);

    test('should paint nothing when off', () {
      final canvas = _RecordingCanvas();
      final frame = _frameOf(
        WireframeNode(
          id: 'root',
          type: 'View',
          rect: const Rect.fromLTWH(0, 0, 100, 100),
          skeletons: <WireframeSkeleton>[
            const WireframeSkeleton(
              rect: Rect.fromLTWH(0, 0, 10, 10),
              color: Color(0xFFFF0000),
            ),
          ],
        ),
      );

      WireframeOverlayPainter(
        frame: frame,
        mode: WireframeOverlayMode.off,
      ).paint(canvas, size);

      expect(canvas.rects, isEmpty);
    });

    test('should paint bounds for every node in bounds mode', () {
      final canvas = _RecordingCanvas();
      final root =
          WireframeNode(
            id: 'root',
            type: 'View',
            rect: const Rect.fromLTWH(0, 0, 100, 100),
          )..addChild(
            WireframeNode(
              id: 'child',
              type: 'SizedBox',
              rect: const Rect.fromLTWH(10, 10, 20, 20),
            ),
          );

      WireframeOverlayPainter(
        frame: _frameOf(root),
        mode: WireframeOverlayMode.bounds,
      ).paint(canvas, size);

      expect(
        canvas.rects.map((entry) => entry.$1),
        containsAll(<Rect>[
          const Rect.fromLTWH(0, 0, 100, 100),
          const Rect.fromLTWH(10, 10, 20, 20),
        ]),
      );
    });

    test('should accumulate opacity down the tree in replay mode', () {
      final canvas = _RecordingCanvas();
      // Each node reports only the opacity it contributes, so a half-opaque
      // node under another half-opaque node is a quarter opaque on screen.
      final root =
          WireframeNode(
            id: 'root',
            type: 'View',
            rect: const Rect.fromLTWH(0, 0, 100, 100),
            opacity: 0.5,
          )..addChild(
            WireframeNode(
              id: 'child',
              type: 'Opacity',
              rect: const Rect.fromLTWH(0, 0, 10, 10),
              opacity: 0.5,
              skeletons: <WireframeSkeleton>[
                const WireframeSkeleton(
                  rect: Rect.fromLTWH(0, 0, 10, 10),
                  color: Color(0xFFFF0000),
                ),
              ],
            ),
          );

      WireframeOverlayPainter(
        frame: _frameOf(root),
        mode: WireframeOverlayMode.replay,
      ).paint(canvas, size);

      final fill = canvas.rects.firstWhere(
        (entry) => entry.$1 == const Rect.fromLTWH(0, 0, 10, 10),
      );

      expect(fill.$2.color.a, closeTo(0.25, 0.001));
    });

    test('should mark a private node even though it has no fills', () {
      final canvas = _RecordingCanvas();
      final root =
          WireframeNode(
            id: 'root',
            type: 'View',
            rect: const Rect.fromLTWH(0, 0, 100, 100),
          )..addChild(
            WireframeNode(
              id: 'secret',
              type: 'RichText',
              rect: const Rect.fromLTWH(5, 5, 30, 12),
              isSensitive: true,
            ),
          );

      WireframeOverlayPainter(
        frame: _frameOf(root),
        mode: WireframeOverlayMode.replay,
      ).paint(canvas, size);

      expect(
        canvas.rects.map((entry) => entry.$1),
        contains(const Rect.fromLTWH(5, 5, 30, 12)),
      );
    });

    test('should repaint when the frame changes', () {
      final root = WireframeNode(
        id: 'root',
        type: 'View',
        rect: const Rect.fromLTWH(0, 0, 100, 100),
      );
      final painter = WireframeOverlayPainter(
        frame: _frameOf(root),
        mode: WireframeOverlayMode.bounds,
      );

      expect(
        painter.shouldRepaint(
          WireframeOverlayPainter(
            frame: _frameOf(root),
            mode: WireframeOverlayMode.bounds,
          ),
        ),
        isTrue,
      );
    });
  });
}
