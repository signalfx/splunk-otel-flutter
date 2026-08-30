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

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/element_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/recording_canvas.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Recorded fills retained between captures, keyed weakly on the render object.
final Expando<_CachedPaint> _cache = Expando<_CachedPaint>(
  'splunkCustomPaintFills',
);

/// Fills recorded for a painter, together with what would invalidate them.
class _CachedPaint {
  const _CachedPaint({
    required this.fills,
    required this.painter,
    required this.foregroundPainter,
    required this.size,
  });

  final List<RecordedFill> fills;
  final CustomPainter? painter;
  final CustomPainter? foregroundPainter;
  final Size size;

  /// Whether [candidate] would draw exactly what [painter] already drew.
  ///
  /// Delegates to the painter's own [CustomPainter.shouldRepaint], which is the
  /// same question Flutter asks before repainting it. A painter recreated on
  /// every build is the normal case, so identity alone would almost never hit.
  static bool _isUnchanged(CustomPainter? cached, CustomPainter? candidate) {
    if (identical(cached, candidate)) {
      return true;
    }
    if (cached == null || candidate == null) {
      return false;
    }
    // shouldRepaint may only be asked about a delegate of its own kind.
    if (cached.runtimeType != candidate.runtimeType) {
      return false;
    }

    try {
      return !candidate.shouldRepaint(cached);
    } catch (_) {
      return false;
    }
  }

  bool matches(RenderCustomPaint renderObject) =>
      size == renderObject.size &&
      _isUnchanged(painter, renderObject.painter) &&
      _isUnchanged(foregroundPainter, renderObject.foregroundPainter);
}

/// Describes `RenderCustomPaint`, the render object behind `CustomPaint`.
///
/// A painter draws directly onto a canvas, so unlike every other descriptor
/// there is nothing to read: the appearance exists only as the sequence of
/// calls the painter would make. It is recovered by handing the painter a
/// [RecordingCanvas] and keeping the rectangles it covers.
///
/// This reaches a large part of Material that is otherwise invisible to
/// capture. Switch, Checkbox, Radio, Slider marks and both progress indicators
/// are painters, as is essentially every charting package.
///
/// Running application code during a walk is the cost. It is contained by
/// invoking the painter inside a guard, by capping how many fills one painter
/// may contribute, and by not calling it again while it reports itself
/// unchanged. A painter that throws forfeits only its own appearance, and a
/// stable one is not re-entered at all, so the common failure costs one report
/// rather than one per frame.
class CustomPaintDescriptor extends ElementDescriptor {
  /// Creates the descriptor.
  const CustomPaintDescriptor();

  @override
  void describeSkeletons(
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {
    final renderObject = context.renderObject;
    if (renderObject is! RenderCustomPaint) {
      return;
    }

    final cached = _cache[renderObject];
    if (cached != null && cached.matches(renderObject)) {
      _emit(cached.fills, context, into);

      return;
    }

    final size = renderObject.size;
    final canvas = RecordingCanvas(size: size);

    // Background first, then foreground, matching the order the two painters
    // reach the screen. The child in between is captured as its own node.
    _record(renderObject.painter, canvas, size);
    _record(renderObject.foregroundPainter, canvas, size);

    // A recording that stood in for an image it had not sampled yet is kept
    // only for this frame, so the real colour is picked up once it arrives.
    if (!canvas.isProvisional) {
      _cache[renderObject] = _CachedPaint(
        fills: canvas.fills,
        painter: renderObject.painter,
        foregroundPainter: renderObject.foregroundPainter,
        size: size,
      );
    }

    _emit(canvas.fills, context, into);
  }

  void _record(CustomPainter? painter, RecordingCanvas canvas, Size size) {
    if (painter == null) {
      return;
    }

    try {
      painter.paint(canvas, size);
    } catch (error, stackTrace) {
      // An application painter is free to assume a real canvas, and some do.
      // Losing one element's appearance is preferable to losing the frame.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'splunk_otel_flutter_session_replay',
          context: ErrorDescription(
            'while recording ${painter.runtimeType} for a session replay frame',
          ),
          silent: true,
        ),
      );
    }
  }

  void _emit(
    List<RecordedFill> fills,
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {
    for (final fill in fills) {
      into.add(
        WireframeSkeleton(
          rect: context.localToView(fill.rect),
          color: fill.color,
          opacity: fill.opacity,
          isText: fill.isText,
        ),
      );
    }
  }
}
