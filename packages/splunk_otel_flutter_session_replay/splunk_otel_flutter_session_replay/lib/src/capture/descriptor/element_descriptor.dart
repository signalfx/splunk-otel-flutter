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

import 'package:flutter/widgets.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Everything a descriptor needs about the element being described.
///
/// Geometry is pre-resolved by the walker so descriptors never repeat the
/// transform work, and never have to know how view-space coordinates are
/// derived.
class DescriptorContext {
  /// Creates a context for [element].
  const DescriptorContext({
    required this.element,
    required this.renderObject,
    required this.rect,
    required this.transform,
  });

  /// Element being described.
  final Element element;

  /// Render object backing [element].
  final RenderBox renderObject;

  /// Bounds of [renderObject] in logical pixels, relative to the view.
  final Rect rect;

  /// Transform from [renderObject]'s local coordinates to view coordinates.
  final Matrix4 transform;

  /// Maps a rectangle in local coordinates into view coordinates.
  ///
  /// Descriptors that read geometry out of a render object, such as text line
  /// boxes, receive it in local coordinates and must convert it before emitting
  /// a skeleton.
  Rect localToView(Rect local) => MatrixUtils.transformRect(transform, local);
}

/// Extracts the visual appearance of one kind of element.
///
/// A node carries geometry and hierarchy; a descriptor supplies the paint. The
/// registry chooses which descriptor applies, so implementations may assume
/// they were matched correctly, but should still fail soft rather than throw if
/// the render object is not in the expected state.
abstract class ElementDescriptor {
  /// Allows subclasses to be const.
  const ElementDescriptor();

  /// Appends the fills that make up this element's appearance.
  ///
  /// Called once per captured frame per matching element, so implementations
  /// must avoid allocation-heavy work and must never trigger layout.
  void describeSkeletons(
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {}

  /// Opacity this element applies to its whole subtree.
  ///
  /// Returns 1.0 for elements that do not affect opacity.
  double describeOpacity(DescriptorContext context) => 1.0;
}
