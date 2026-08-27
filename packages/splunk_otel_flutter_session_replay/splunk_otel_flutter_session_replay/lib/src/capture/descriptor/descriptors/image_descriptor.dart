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

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/element_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Describes `RenderImage` as a flat placeholder block.
///
/// Sampling the real image would mean reading pixels back off the GPU, which is
/// asynchronous and cannot complete inside a synchronous capture. A neutral
/// block preserves the layout, which is what a wireframe is for; deriving a
/// representative colour is left to a later pass that can await decoding.
class ImageDescriptor extends ElementDescriptor {
  /// Creates the descriptor, optionally overriding [placeholderColor].
  const ImageDescriptor({this.placeholderColor = const Color(0xFF9E9E9E)});

  /// Colour used to stand in for image content.
  final Color placeholderColor;

  @override
  void describeSkeletons(
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {
    final renderObject = context.renderObject;
    if (renderObject is! RenderImage || renderObject.image == null) {
      return;
    }

    into.add(WireframeSkeleton(rect: context.rect, color: placeholderColor));
  }
}
