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

import 'package:flutter/material.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// How much of the captured wireframe to draw.
enum WireframeOverlayMode {
  /// Draw nothing.
  off,

  /// Draw only node bounds, revealing the structure over the live interface.
  bounds,

  /// Draw the captured fills on an opaque backdrop, showing the wireframe as a
  /// replay consumer would receive it.
  replay,
}

/// Draws a captured frame back over the running application.
///
/// Frames are captured in logical pixels relative to their view, and this
/// painter is sized to that same view, so node rectangles are used directly
/// with no transform. A mismatch between the two would show up immediately as a
/// visible offset, which is the point: the overlay doubles as a check that
/// capture geometry is correct.
class WireframeOverlayPainter extends CustomPainter {
  /// Creates a painter for [frame].
  WireframeOverlayPainter({
    required this.frame,
    required this.mode,
    this.highlightedNodeId,
  });

  /// Frame to draw.
  final WireframeFrame frame;

  /// How much of the frame to draw.
  final WireframeOverlayMode mode;

  /// Node to outline prominently, typically the tree explorer's selection.
  final String? highlightedNodeId;

  static const Color _boundsColor = Color(0x5500E5FF);
  static const Color _sensitiveColor = Color(0x88FF1744);
  static const Color _highlightColor = Color(0xFFFFEA00);
  static const Color _replayBackdrop = Color(0xFF212121);

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == WireframeOverlayMode.off) {
      return;
    }

    if (mode == WireframeOverlayMode.replay) {
      canvas.drawRect(Offset.zero & size, Paint()..color = _replayBackdrop);
    }

    final boundsPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _boundsColor;

    _paintNode(canvas, frame.root, boundsPaint, 1);
  }

  void _paintNode(
    Canvas canvas,
    WireframeNode node,
    Paint boundsPaint,
    double inheritedOpacity,
  ) {
    // Each node reports only the opacity it contributes itself, so a consumer
    // has to accumulate down the tree to arrive at what is actually visible.
    final opacity = inheritedOpacity * node.opacity;

    if (mode == WireframeOverlayMode.bounds) {
      canvas.drawRect(node.rect, boundsPaint);
    } else {
      for (final skeleton in node.skeletons) {
        canvas.drawRect(
          skeleton.rect,
          Paint()
            ..color = skeleton.color.withValues(
              alpha: (opacity * skeleton.effectiveOpacity).clamp(0.0, 1.0),
            ),
        );
      }
    }

    // Drawn in both modes: the whole point of masking is to be able to see at a
    // glance that it covered what was intended.
    if (node.isSensitive) {
      canvas.drawRect(node.rect, Paint()..color = _sensitiveColor);
    }

    if (node.id == highlightedNodeId) {
      canvas.drawRect(
        node.rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _highlightColor,
      );
    }

    for (final child in node.children) {
      _paintNode(canvas, child, boundsPaint, opacity);
    }
  }

  @override
  bool shouldRepaint(WireframeOverlayPainter oldDelegate) =>
      !identical(oldDelegate.frame, frame) ||
      oldDelegate.mode != mode ||
      oldDelegate.highlightedNodeId != highlightedNodeId;
}
