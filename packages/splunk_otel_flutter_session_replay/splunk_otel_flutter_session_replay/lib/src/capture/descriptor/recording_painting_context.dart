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

import 'package:flutter/rendering.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/recording_canvas.dart';

/// A [PaintingContext] that hands a render object a [RecordingCanvas] instead of
/// a real one.
///
/// Some render objects paint themselves directly rather than describing their
/// appearance in readable properties. A slider is the clearest example: its
/// track and thumb exist only as the calls its theme shapes make while
/// painting, so nothing about it can be read.
///
/// Every layer-pushing method is redirected onto the recorder so that clips,
/// transforms and opacities applied while painting still reach the recorded
/// shapes. No real layer is ever produced, and children are skipped, because the
/// walk visits them itself and painting them here would report them twice.
class RecordingPaintingContext extends PaintingContext {
  /// Records into [recording] for a render object covering [estimatedBounds].
  RecordingPaintingContext(this.recording, Rect estimatedBounds)
    : super(ContainerLayer(), estimatedBounds);

  /// Canvas collecting the shapes.
  final RecordingCanvas recording;

  @override
  Canvas get canvas => recording;

  @override
  void paintChild(RenderObject child, Offset offset) {}

  @override
  ClipRectLayer? pushClipRect(
    bool needsCompositing,
    Offset offset,
    Rect clipRect,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.hardEdge,
    ClipRectLayer? oldLayer,
  }) {
    _clipped(clipBehavior, clipRect.shift(offset), painter, offset);

    return null;
  }

  @override
  ClipRRectLayer? pushClipRRect(
    bool needsCompositing,
    Offset offset,
    Rect bounds,
    RRect clipRRect,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.antiAlias,
    ClipRRectLayer? oldLayer,
  }) {
    _clipped(clipBehavior, clipRRect.outerRect.shift(offset), painter, offset);

    return null;
  }

  @override
  ClipPathLayer? pushClipPath(
    bool needsCompositing,
    Offset offset,
    Rect bounds,
    Path clipPath,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.antiAlias,
    ClipPathLayer? oldLayer,
  }) {
    _clipped(clipBehavior, clipPath.getBounds().shift(offset), painter, offset);

    return null;
  }

  @override
  TransformLayer? pushTransform(
    bool needsCompositing,
    Offset offset,
    Matrix4 transform,
    PaintingContextCallback painter, {
    TransformLayer? oldLayer,
  }) {
    // Matches how a real context folds the offset around the transform, so a
    // transformed shape lands where it would have been painted.
    final effective = Matrix4.translationValues(offset.dx, offset.dy, 0)
      ..multiply(transform)
      ..translateByDouble(-offset.dx, -offset.dy, 0, 1);

    recording.save();
    recording.transform(effective.storage);
    painter(this, offset);
    recording.restore();

    return null;
  }

  @override
  OpacityLayer pushOpacity(
    Offset offset,
    int alpha,
    PaintingContextCallback painter, {
    OpacityLayer? oldLayer,
  }) {
    recording.saveLayer(null, Paint()..color = Color.fromARGB(alpha, 0, 0, 0));
    painter(this, offset);
    recording.restore();

    return OpacityLayer();
  }

  @override
  void pushLayer(
    ContainerLayer childLayer,
    PaintingContextCallback painter,
    Offset offset, {
    Rect? childPaintBounds,
  }) => painter(this, offset);

  void _clipped(
    Clip clipBehavior,
    Rect clip,
    PaintingContextCallback painter,
    Offset offset,
  ) {
    if (clipBehavior == Clip.none) {
      painter(this, offset);

      return;
    }

    recording.save();
    recording.clipRect(clip);
    painter(this, offset);
    recording.restore();
  }
}
