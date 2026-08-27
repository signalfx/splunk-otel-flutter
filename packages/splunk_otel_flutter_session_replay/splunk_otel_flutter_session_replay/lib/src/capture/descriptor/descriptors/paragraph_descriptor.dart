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

/// Font family Flutter's built-in icon set renders with.
const String _iconFontFamily = 'MaterialIcons';

/// Colour the engine paints text with when no colour is resolved anywhere in
/// the span tree.
const Color _defaultTextColor = Color(0xFF000000);

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

    _describeSpan(
      span: renderObject.text,
      inherited: null,
      offset: 0,
      renderObject: renderObject,
      context: context,
      into: into,
    );
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
    required DescriptorContext context,
    required List<WireframeSkeleton> into,
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
        context: context,
        into: into,
      );
    }

    for (final child in span.children ?? const <InlineSpan>[]) {
      end = _describeSpan(
        span: child,
        inherited: style,
        offset: end,
        renderObject: renderObject,
        context: context,
        into: into,
      );
    }

    return end;
  }

  /// Emits one skeleton per line box covered by the text range [start], [end].
  void _emitRun({
    required int start,
    required int end,
    required TextStyle? style,
    required RenderParagraph renderObject,
    required DescriptorContext context,
    required List<WireframeSkeleton> into,
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

      into.add(
        WireframeSkeleton(
          rect: context.localToView(local),
          color: color,
          isText: isText,
        ),
      );
    }
  }
}
