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

import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/rendering.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/element_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Font family Flutter's built-in icon set renders with.
const String _iconFontFamily = 'MaterialIcons';

/// Colour the engine paints text with when no colour is resolved anywhere in
/// the span tree.
const Color _defaultTextColor = Color(0xFF000000);

/// Line boxes retained between captures, keyed weakly on the render object.
///
/// Querying line boxes is the most expensive single step of a capture, and text
/// usually survives many frames unchanged. An [Expando] keeps this a pure cache:
/// entries are collected together with the paragraph they describe, so nothing
/// here extends the lifetime of the render tree.
final Expando<_CachedParagraph> _cache = Expando<_CachedParagraph>(
  'splunkParagraphSkeletons',
);

/// One line box in the paragraph's own coordinate space.
///
/// Stored unprojected so the cache survives the paragraph moving. Only the
/// projection is redone when a cached entry is reused, which is arithmetic
/// rather than a text query.
class _CachedBox {
  const _CachedBox({
    required this.rect,
    required this.color,
    required this.isText,
  });

  final Rect rect;
  final Color color;
  final bool isText;
}

/// Cached line boxes plus every input that could change them.
///
/// The key is deliberately exhaustive over `RenderParagraph`'s layout inputs.
/// Size alone is not enough: changing [textAlign] moves every box while leaving
/// the paragraph exactly the same size, which would otherwise serve boxes at
/// stale positions.
class _CachedParagraph {
  _CachedParagraph({required this.boxes, required RenderParagraph source})
    : text = source.text,
      size = source.size,
      textAlign = source.textAlign,
      textDirection = source.textDirection,
      softWrap = source.softWrap,
      overflow = source.overflow,
      textScaler = source.textScaler,
      maxLines = source.maxLines,
      locale = source.locale,
      strutStyle = source.strutStyle,
      textWidthBasis = source.textWidthBasis,
      textHeightBehavior = source.textHeightBehavior;

  final List<_CachedBox> boxes;
  final InlineSpan text;
  final Size size;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final bool softWrap;
  final TextOverflow overflow;
  final TextScaler textScaler;
  final int? maxLines;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final ui.TextHeightBehavior? textHeightBehavior;

  /// Whether [source] would still produce these boxes.
  bool matches(RenderParagraph source) =>
      size == source.size &&
      textAlign == source.textAlign &&
      textDirection == source.textDirection &&
      softWrap == source.softWrap &&
      overflow == source.overflow &&
      textScaler == source.textScaler &&
      maxLines == source.maxLines &&
      locale == source.locale &&
      strutStyle == source.strutStyle &&
      textWidthBasis == source.textWidthBasis &&
      textHeightBehavior == source.textHeightBehavior &&
      // Compared last: the only key that can recurse over a span tree.
      text == source.text;
}

/// Describes `RenderParagraph`, the render object behind `Text` and `RichText`.
///
/// Line boxes come from the paragraph that was already laid out for this frame,
/// so no text is measured a second time. The style is read from the render
/// object rather than the `Text` widget because only the render object holds the
/// style after `DefaultTextStyle` and theme resolution have been applied; the
/// widget's own `style` is frequently null even when the text is visibly
/// coloured.
class ParagraphDescriptor extends ElementDescriptor {
  /// Creates the descriptor.
  const ParagraphDescriptor();

  @override
  void describeSkeletons(
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {
    final renderObject = context.renderObject;
    if (renderObject is! RenderParagraph) {
      return;
    }

    var cached = _cache[renderObject];
    if (cached == null || !cached.matches(renderObject)) {
      final boxes = <_CachedBox>[];
      _describeSpan(
        span: renderObject.text,
        inherited: null,
        offset: 0,
        renderObject: renderObject,
        into: boxes,
      );
      cached = _CachedParagraph(boxes: boxes, source: renderObject);
      _cache[renderObject] = cached;
    }

    for (final box in cached.boxes) {
      into.add(
        WireframeSkeleton(
          rect: context.localToView(box.rect),
          color: box.color,
          isText: box.isText,
        ),
      );
    }
  }

  /// Walks the span tree in document order, emitting one run of skeletons per
  /// styled segment, and returns the text offset just past [span].
  ///
  /// Offsets are tracked manually because selection ranges address the flattened
  /// text while colours are only known per span.
  int _describeSpan({
    required InlineSpan span,
    required TextStyle? inherited,
    required int offset,
    required RenderParagraph renderObject,
    required List<_CachedBox> into,
  }) {
    if (span is! TextSpan) {
      // Placeholders occupy a single object replacement character, and are
      // captured through their own render objects.
      return span is PlaceholderSpan ? offset + 1 : offset;
    }

    final style = inherited?.merge(span.style) ?? span.style;
    var end = offset;

    final text = span.text;
    if (text != null && text.isNotEmpty) {
      end += text.length;
      _emitRun(
        start: offset,
        end: end,
        style: style,
        renderObject: renderObject,
        into: into,
      );
    }

    for (final child in span.children ?? const <InlineSpan>[]) {
      end = _describeSpan(
        span: child,
        inherited: style,
        offset: end,
        renderObject: renderObject,
        into: into,
      );
    }

    return end;
  }

  /// Emits one box per line covered by the text range [start], [end].
  void _emitRun({
    required int start,
    required int end,
    required TextStyle? style,
    required RenderParagraph renderObject,
    required List<_CachedBox> into,
  }) {
    final color = style?.color ?? _defaultTextColor;
    if (color.a == 0) {
      return;
    }

    // Icons are glyphs but not text: masking them as text would hide the shape
    // that carries the meaning.
    final isText = style?.fontFamily != _iconFontFamily;

    final boxes = renderObject.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
    );

    for (final box in boxes) {
      final local = box.toRect();
      if (local.isEmpty) {
        continue;
      }

      into.add(_CachedBox(rect: local, color: color, isText: isText));
    }
  }
}
