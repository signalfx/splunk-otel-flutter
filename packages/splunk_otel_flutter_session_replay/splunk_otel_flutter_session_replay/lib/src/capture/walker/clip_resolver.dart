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

/// Decides whether a render object confines its children to its own bounds.
///
/// Without this the capture reports a half-scrolled list row at its full
/// height, and a replay paints the hidden part over whatever sits above the
/// viewport. That is the one class of gap that produces wrong output rather
/// than missing output, which is why clipping is resolved for every node rather
/// than only for the types that paint.
///
/// Resolution is a short chain of `is` checks rather than a dynamic read of
/// `clipBehavior`. Most render objects have no such member, so a dynamic probe
/// would throw `NoSuchMethodError` for the majority of nodes on every frame,
/// and thrown exceptions are far more expensive than the type tests they would
/// replace.
///
/// The clip is always taken as the render object's own bounds. A few of these
/// types can clip to something smaller through a custom `CustomClipper` or a
/// rounded shape, in which case the capture shows slightly more than the real
/// interface does. Reading the clipper would mean invoking application code
/// part-way through a walk, which is a correctness risk out of proportion to
/// the accuracy it buys.
bool clipsChildren(RenderObject renderObject) => switch (renderObject) {
  RenderClipRect() => renderObject.clipBehavior != Clip.none,
  RenderClipRRect() => renderObject.clipBehavior != Clip.none,
  RenderClipOval() => renderObject.clipBehavior != Clip.none,
  RenderClipPath() => renderObject.clipBehavior != Clip.none,
  RenderPhysicalModel() => renderObject.clipBehavior != Clip.none,
  RenderPhysicalShape() => renderObject.clipBehavior != Clip.none,
  RenderViewportBase<dynamic>() => renderObject.clipBehavior != Clip.none,
  RenderStack() => renderObject.clipBehavior != Clip.none,
  RenderFlex() => renderObject.clipBehavior != Clip.none,
  RenderEditable() => renderObject.clipBehavior != Clip.none,
  _ => false,
};

/// Narrows [inherited] by [addition], treating null as unbounded.
Rect? intersectClip(Rect? inherited, Rect addition) =>
    inherited == null ? addition : inherited.intersect(addition);

/// Whether [inner] lies entirely within [outer], edges included.
///
/// [Rect.contains] treats the right and bottom edges as outside, which would
/// report a fill flush against its container as needing to be trimmed.
bool containsRect(Rect outer, Rect inner) =>
    inner.left >= outer.left &&
    inner.top >= outer.top &&
    inner.right <= outer.right &&
    inner.bottom <= outer.bottom;
