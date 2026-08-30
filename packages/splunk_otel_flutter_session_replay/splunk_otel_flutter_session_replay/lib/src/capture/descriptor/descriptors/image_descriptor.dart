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
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/image_sampler.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Describes `RenderImage` as the rectangle it paints, in its average colour.
///
/// Two things make an image harder than a solid box. Its colour can only be
/// learned by reading pixels back, which is asynchronous and so cannot happen
/// inside a capture; and it rarely fills its own bounds, since `BoxFit` and
/// alignment decide where within the box it actually lands.
///
/// The colour is therefore sampled off the capture path, once per decoded
/// image, and cached. Until that finishes the image is reported in
/// [placeholderColor], which costs the first frame or two of a replay and keeps
/// every capture synchronous.
class ImageDescriptor extends ElementDescriptor {
  /// Creates the descriptor, optionally overriding [placeholderColor].
  const ImageDescriptor({this.placeholderColor = unknownContentColor});

  /// Colour used until an image has been sampled.
  final Color placeholderColor;

  @override
  void describeSkeletons(
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {
    final renderObject = context.renderObject;
    if (renderObject is! RenderImage) {
      return;
    }

    final image = renderObject.image;
    if (image == null) {
      return;
    }

    final rect = context.localToView(paintedRect(renderObject));
    if (rect.isEmpty) {
      return;
    }

    final opacity = renderObject.opacity?.value ?? 1.0;
    final sample = sampleOf(image);

    if (sample == null) {
      into.add(
        WireframeSkeleton(
          rect: rect,
          color: placeholderColor,
          opacity: opacity,
        ),
      );

      return;
    }

    // Nothing of the image is opaque enough to be worth a rectangle.
    if (sample.coverage <= 0) {
      return;
    }

    into.add(
      WireframeSkeleton(
        rect: rect,
        color: _tinted(renderObject, sample),
        opacity: opacity,
      ),
    );
  }

  /// Colour to report, accounting for a tint applied by the widget.
  ///
  /// `Image(color: ...)` paints the picture entirely in one colour and keeps
  /// only its shape, which is how a tinted icon works. The sampled colour is
  /// then irrelevant, but its coverage still is: it says how much of the box
  /// the shape occupies.
  Color _tinted(RenderImage renderObject, ImageSample sample) {
    final tint = renderObject.color;
    final blend = renderObject.colorBlendMode ?? BlendMode.srcIn;
    final replacesColor =
        blend == BlendMode.srcIn || blend == BlendMode.srcATop;

    if (tint == null || !replacesColor) {
      return sample.fill;
    }

    return tint.withValues(alpha: tint.a * sample.coverage);
  }
}

/// Rectangle [renderObject] actually paints into, in its own coordinates.
///
/// Available on the first frame: the pixel dimensions come from the decoded
/// image the render object already holds, so only the colour has to wait.
@visibleForTesting
Rect paintedRect(RenderImage renderObject) {
  final box = Offset.zero & renderObject.size;
  final image = renderObject.image;
  if (image == null) {
    return box;
  }

  return fittedImageRect(
    imageSize: Size(image.width.toDouble(), image.height.toDouble()),
    box: box,
    fit: renderObject.fit,
    alignment: renderObject.alignment,
    scale: renderObject.scale,
    repeat: renderObject.repeat,
    centerSlice: renderObject.centerSlice,
    matchTextDirection: renderObject.matchTextDirection,
    textDirection: renderObject.textDirection,
  );
}
