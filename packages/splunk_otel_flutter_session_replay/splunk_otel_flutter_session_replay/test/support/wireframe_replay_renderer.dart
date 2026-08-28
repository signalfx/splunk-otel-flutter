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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Renders a captured frame the way a replay consumer would, so that capture
/// fidelity can be judged against the real interface rather than against
/// assertions about the model.
///
/// Deliberately test-only. The SDK never replays frames itself, so shipping a
/// renderer would be production code that only tests use.
///
/// Nothing is drawn for a masked node. Capture already withholds its skeletons,
/// and drawing a placeholder here would make it impossible to tell "masked" from
/// "reproduced in some other colour".
class WireframeReplayPainter extends CustomPainter {
  /// Creates a painter for [frame].
  const WireframeReplayPainter(this.frame);

  /// Frame to draw.
  final WireframeFrame frame;

  @override
  void paint(Canvas canvas, Size size) => _paintNode(canvas, frame.root, 1);

  void _paintNode(Canvas canvas, WireframeNode node, double inheritedOpacity) {
    // Nodes report only their own contribution, so a consumer accumulates down
    // the tree to arrive at what is actually visible.
    final opacity = inheritedOpacity * node.opacity;

    for (final skeleton in node.skeletons) {
      canvas.drawRect(
        skeleton.rect,
        Paint()
          ..color = skeleton.color.withValues(
            alpha: (opacity * skeleton.effectiveOpacity).clamp(0.0, 1.0),
          ),
      );
    }

    for (final child in node.children) {
      _paintNode(canvas, child, opacity);
    }
  }

  @override
  bool shouldRepaint(WireframeReplayPainter oldDelegate) =>
      !identical(oldDelegate.frame, frame);
}

/// Rasterises [frame] at one pixel per logical pixel.
ui.Image rasterizeWireframe(WireframeFrame frame) {
  final size = frame.viewSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & size);

  WireframeReplayPainter(frame).paint(canvas, size);

  return recorder.endRecording().toImageSync(
    size.width.ceil(),
    size.height.ceil(),
  );
}

/// Rasterises what the application actually draws, for comparison.
///
/// [boundaryKey] must mark a [RepaintBoundary] that fills the view, so that its
/// image shares an origin with the captured frame.
ui.Image rasterizeApplication(WidgetTester tester, Key boundaryKey) => tester
    .renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey))
    .toImageSync();

/// Random access to the pixels of a rasterised image.
class Pixels {
  Pixels._(this._bytes, this.width, this.height);

  final ByteData _bytes;

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Reads [image] so individual pixels can be sampled.
  ///
  /// Decoding needs real asynchrony, which a widget test only has inside
  /// [WidgetTester.runAsync].
  static Future<Pixels> from(WidgetTester tester, ui.Image image) async {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );

    return Pixels._(bytes!, image.width, image.height);
  }

  /// Colour at ([x], [y]).
  Color at(double x, double y) {
    final offset = ((y.floor() * width) + x.floor()) * 4;

    return Color.fromARGB(
      _bytes.getUint8(offset + 3),
      _bytes.getUint8(offset),
      _bytes.getUint8(offset + 1),
      _bytes.getUint8(offset + 2),
    );
  }

  /// Whether any pixel within [rect] is [color].
  bool containsColorIn(Rect rect, Color color) {
    for (var y = rect.top.floor(); y < rect.bottom.ceil(); y++) {
      for (var x = rect.left.floor(); x < rect.right.ceil(); x++) {
        if (x < 0 || y < 0 || x >= width || y >= height) {
          continue;
        }
        if (at(x.toDouble(), y.toDouble()) == color) {
          return true;
        }
      }
    }

    return false;
  }

  /// Whether any pixel in the whole image is [color].
  bool containsColor(Color color) => containsColorIn(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    color,
  );
}
