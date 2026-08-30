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

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/image_sampler.dart';

/// One rectangle a painter covered, in the painter's own coordinates.
class RecordedFill {
  /// Creates a fill.
  const RecordedFill({
    required this.rect,
    required this.color,
    this.opacity = 1.0,
    this.isText = false,
  });

  /// Area covered, already projected through the canvas transform.
  final Rect rect;

  /// Colour the painter used.
  final Color color;

  /// Opacity contributed by enclosing layers.
  final double opacity;

  /// Whether this came from text drawn directly onto the canvas.
  final bool isText;
}

/// A [Canvas] that records the area and colour of each draw instead of
/// rasterising it.
///
/// This is how a painter that draws itself, rather than composing child render
/// objects, can be represented at all. Switches, checkboxes, radios, progress
/// indicators and every application chart paint straight onto a canvas, so
/// there is no render object underneath describing what they look like. Handing
/// the painter one of these recovers the shapes it would have drawn.
///
/// Only the members needed to follow a painter are implemented. The rest are
/// absorbed by [noSuchMethod], which is deliberate: `Canvas` gains methods
/// between Flutter releases, and an SDK that implemented the interface
/// exhaustively would stop compiling in its consumers' applications the moment
/// one was added. Unhandled draws are simply not recorded.
///
/// Shapes are reduced to rectangles because that is all the wire format
/// carries. A stroked shape becomes the four bands of its outline rather than a
/// solid block, so an outline is never mistaken for a filled area.
class RecordingCanvas implements Canvas {
  /// Records fills for a painter of [size].
  ///
  /// [maxFills] bounds the work an application painter can cause. A chart
  /// drawing thousands of segments would otherwise put thousands of skeletons
  /// on the wire for a single node, every frame.
  RecordingCanvas({required this.size, this.maxFills = 64});

  /// Size the painter was asked to paint.
  final Size size;

  /// Upper bound on recorded fills.
  final int maxFills;

  /// Recorded fills, in draw order.
  final List<RecordedFill> fills = <RecordedFill>[];

  Matrix4 _transform = Matrix4.identity();
  Rect? _clip;
  double _opacity = 1.0;
  final List<({Matrix4 transform, Rect? clip, double opacity})> _stack =
      <({Matrix4 transform, Rect? clip, double opacity})>[];

  /// Whether recording stopped early because [maxFills] was reached.
  bool get isSaturated => fills.length >= maxFills;

  bool _isProvisional = false;

  /// Whether some of what was recorded stands in for content not yet known.
  ///
  /// A recording that drew an image before it had been sampled is only as good
  /// as its placeholder, so callers that cache recordings should record again
  /// rather than keep this one for the life of the painter.
  bool get isProvisional => _isProvisional;

  void _add(Rect local, Paint paint, {bool isText = false}) =>
      _addColor(local, _colorOf(paint), isText: isText);

  /// The colour a paint will produce, as far as it can be known.
  ///
  /// A paint carrying a shader — a gradient, or an image used as a fill —
  /// leaves `color` at its default opaque black, which would report a gradient
  /// chart as a black block. The shader itself is opaque to Dart, so what it
  /// would produce cannot be recovered; a neutral colour at least keeps the
  /// shape without asserting a colour that is certainly wrong.
  Color _colorOf(Paint paint) =>
      paint.shader == null ? paint.color : unknownContentColor;

  void _addColor(Rect local, Color color, {bool isText = false}) {
    if (isSaturated) {
      return;
    }

    if (color.a == 0 || local.isEmpty) {
      return;
    }

    var rect = MatrixUtils.transformRect(_transform, local);
    final clip = _clip;
    if (clip != null) {
      rect = rect.intersect(clip);
    }
    if (rect.isEmpty) {
      return;
    }

    fills.add(
      RecordedFill(rect: rect, color: color, opacity: _opacity, isText: isText),
    );
  }

  /// Records the outline of [bounds] as four bands, or as a solid fill when the
  /// stroke is wide enough to close the shape.
  void _addStroke(Rect bounds, Paint paint) {
    final width = paint.strokeWidth <= 0 ? 1.0 : paint.strokeWidth;
    final outer = bounds.inflate(width / 2);
    final inner = bounds.deflate(width / 2);

    if (inner.isEmpty) {
      _add(outer, paint);

      return;
    }

    _add(Rect.fromLTRB(outer.left, outer.top, outer.right, inner.top), paint);
    _add(
      Rect.fromLTRB(outer.left, inner.bottom, outer.right, outer.bottom),
      paint,
    );
    _add(Rect.fromLTRB(outer.left, inner.top, inner.left, inner.bottom), paint);
    _add(
      Rect.fromLTRB(inner.right, inner.top, outer.right, inner.bottom),
      paint,
    );
  }

  /// Records [bounds] as a fill or an outline according to the paint style.
  void _addShape(Rect bounds, Paint paint) {
    if (paint.style == PaintingStyle.stroke) {
      _addStroke(bounds, paint);

      return;
    }

    _add(bounds, paint);
  }

  @override
  void save() => _stack.add((
    transform: Matrix4.copy(_transform),
    clip: _clip,
    opacity: _opacity,
  ));

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    save();
    // A layer is the usual way a painter fades a group of shapes, so its alpha
    // has to reach the shapes drawn inside it.
    _opacity *= paint.color.a;
  }

  @override
  void restore() {
    if (_stack.isEmpty) {
      return;
    }

    final state = _stack.removeLast();
    _transform = state.transform;
    _clip = state.clip;
    _opacity = state.opacity;
  }

  @override
  int getSaveCount() => _stack.length + 1;

  @override
  void restoreToCount(int count) {
    while (_stack.length >= count && _stack.isNotEmpty) {
      restore();
    }
  }

  @override
  void translate(double dx, double dy) =>
      _transform.translateByDouble(dx, dy, 0, 1);

  @override
  void scale(double sx, [double? sy]) =>
      _transform.scaleByDouble(sx, sy ?? sx, 1, 1);

  @override
  void rotate(double radians) => _transform.rotateZ(radians);

  @override
  void skew(double sx, double sy) => _transform.multiply(
    Matrix4.identity()
      ..setEntry(0, 1, sx)
      ..setEntry(1, 0, sy),
  );

  @override
  void transform(Float64List matrix4) =>
      _transform.multiply(Matrix4.fromFloat64List(matrix4));

  @override
  Float64List getTransform() => Float64List.fromList(_transform.storage);

  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    if (clipOp == ui.ClipOp.difference) {
      // Subtracting a region cannot be expressed as a rectangle, so the clip is
      // left as it was and the capture shows slightly more than it should.
      return;
    }

    final projected = MatrixUtils.transformRect(_transform, rect);
    _clip = _clip == null ? projected : _clip!.intersect(projected);
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) =>
      clipRect(rrect.outerRect);

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) =>
      clipRect(path.getBounds());

  @override
  Rect getLocalClipBounds() {
    final clip = _clip ?? (Offset.zero & size);

    return MatrixUtils.transformRect(
      Matrix4.tryInvert(_transform) ?? Matrix4.identity(),
      clip,
    );
  }

  @override
  Rect getDestinationClipBounds() => _clip ?? (Offset.zero & size);

  @override
  void drawRect(Rect rect, Paint paint) => _addShape(rect, paint);

  @override
  void drawRRect(RRect rrect, Paint paint) => _addShape(rrect.outerRect, paint);

  @override
  void drawOval(Rect rect, Paint paint) => _addShape(rect, paint);

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      _addShape(Rect.fromCircle(center: c, radius: radius), paint);

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) => _addShape(rect, paint);

  @override
  void drawPath(Path path, Paint paint) => _addShape(path.getBounds(), paint);

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    // The difference of two rounded rectangles is how a ring or a border is
    // drawn, so it is recorded as the bands between them rather than as the
    // solid outer shape.
    final outerRect = outer.outerRect;
    final innerRect = inner.outerRect;

    if (innerRect.isEmpty || !outerRect.overlaps(innerRect)) {
      _add(outerRect, paint);

      return;
    }

    _add(
      Rect.fromLTRB(
        outerRect.left,
        outerRect.top,
        outerRect.right,
        innerRect.top,
      ),
      paint,
    );
    _add(
      Rect.fromLTRB(
        outerRect.left,
        innerRect.bottom,
        outerRect.right,
        outerRect.bottom,
      ),
      paint,
    );
    _add(
      Rect.fromLTRB(
        outerRect.left,
        innerRect.top,
        innerRect.left,
        innerRect.bottom,
      ),
      paint,
    );
    _add(
      Rect.fromLTRB(
        innerRect.right,
        innerRect.top,
        outerRect.right,
        innerRect.bottom,
      ),
      paint,
    );
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    final width = paint.strokeWidth <= 0 ? 1.0 : paint.strokeWidth;

    // A diagonal line is reported as the rectangle enclosing it, which is the
    // same treatment rotated content gets everywhere else in the capture.
    _add(Rect.fromPoints(p1, p2).inflate(width / 2), paint);
  }

  @override
  void drawPaint(Paint paint) => _add(_clip ?? (Offset.zero & size), paint);

  @override
  void drawImage(ui.Image image, Offset offset, Paint paint) => _addImage(
    image,
    Rect.fromLTWH(
      offset.dx,
      offset.dy,
      image.width.toDouble(),
      image.height.toDouble(),
    ),
    paint,
  );

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) =>
      _addImage(image, dst, paint);

  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) =>
      _addImage(image, dst, paint);

  /// Records an image as the colour it averages out to.
  ///
  /// A paint used to draw an image carries no colour of its own, so taking
  /// `paint.color` would report every picture as black. The sampler answers
  /// with the average colour of images it has already looked at, and starts
  /// looking at ones it has not; until then the image is a neutral block.
  void _addImage(ui.Image image, Rect dst, Paint paint) {
    final sample = sampleOf(image);
    if (sample == null) {
      _isProvisional = true;
    }

    final color = sample == null ? unknownContentColor : sample.fill;

    _addColor(dst, color.withValues(alpha: color.a * paint.color.a));
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    // Text painted straight onto a canvas is still text, so it is marked as
    // such and reduced to its box. No characters are read here, and none could
    // be: only the laid-out geometry is available.
    if (isSaturated) {
      return;
    }

    final rect = MatrixUtils.transformRect(
      _transform,
      Rect.fromLTWH(
        offset.dx,
        offset.dy,
        paragraph.longestLine,
        paragraph.height,
      ),
    );
    final clip = _clip;
    final clipped = clip == null ? rect : rect.intersect(clip);
    if (clipped.isEmpty) {
      return;
    }

    fills.add(
      RecordedFill(
        rect: clipped,
        // The engine holds the resolved colour inside the paragraph, where it
        // cannot be read back, so text is recorded at the default ink colour.
        color: const Color(0xFF000000),
        opacity: _opacity,
        isText: true,
      ),
    );
  }

  /// Absorbs the parts of [Canvas] this recorder does not follow.
  ///
  /// Returning null is safe because every absorbed member returns void; the
  /// ones with a value are implemented above.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
