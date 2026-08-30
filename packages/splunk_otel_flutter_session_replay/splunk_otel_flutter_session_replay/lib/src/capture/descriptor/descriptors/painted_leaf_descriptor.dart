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
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/recording_painting_context.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Render objects whose paint has already failed once.
///
/// Unlike a `CustomPainter`, a render object offers nothing to ask whether it
/// has changed, so there is no cache to fall back on. Remembering the failure is
/// what keeps a render object that cannot survive an out-of-band paint from
/// throwing on every frame for the rest of the session.
final Expando<bool> _failed = Expando<bool>('splunkPaintRecordingFailed');

/// Whether [renderObject] has no children.
///
/// A childless render box either paints something itself or is invisible, which
/// is what makes it safe to reach for its paint method. A render object with
/// children is a container: whatever it contributes is described by its own
/// properties, and its children are visited by the walk.
bool isLeaf(RenderObject renderObject) {
  var hasChild = false;
  renderObject.visitChildren((_) => hasChild = true);

  return !hasChild;
}

/// Describes a render object that draws itself and exposes nothing to read.
///
/// The last resort of the registry. Where a descriptor reads properties, this
/// asks the render object to paint onto a [RecordingCanvas] and keeps the
/// shapes it covers. `Slider` is the case in Material that needs it: its track
/// and thumb come from theme shape objects that paint directly, so no property
/// on the render object describes what is on screen.
///
/// Applied only to childless render objects, and only when no other descriptor
/// matched. Painting is application code running outside a frame, so a render
/// object that does not survive it is remembered and never asked again.
class PaintedLeafDescriptor extends ElementDescriptor {
  /// Creates the descriptor.
  const PaintedLeafDescriptor();

  @override
  void describeSkeletons(
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {
    final renderObject = context.renderObject;
    if (_failed[renderObject] ?? false) {
      return;
    }

    final recording = RecordingCanvas(size: renderObject.size);

    try {
      renderObject.paint(
        RecordingPaintingContext(recording, Offset.zero & renderObject.size),
        Offset.zero,
      );
    } catch (error, stackTrace) {
      _failed[renderObject] = true;

      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'splunk_otel_flutter_session_replay',
          context: ErrorDescription(
            'while recording ${renderObject.runtimeType} for a session replay '
            'frame; it will not be recorded again',
          ),
          silent: true,
        ),
      );

      return;
    }

    for (final fill in recording.fills) {
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
