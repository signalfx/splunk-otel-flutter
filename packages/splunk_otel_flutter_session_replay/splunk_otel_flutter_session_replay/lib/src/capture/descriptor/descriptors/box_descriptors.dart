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
import 'package:flutter/widgets.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/dynamic_property.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/element_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Describes a `ColoredBox`, the widget behind `Container(color: ...)`.
///
/// Dispatch happens on the widget type because the render object is the private
/// `_RenderColoredBox`, whose `Type` cannot be written in source. The colour
/// itself still comes from the render object: `_RenderColoredBox` is a private
/// class with a public `color` getter, so it is reachable through a dynamic
/// selector even though its type is not.
///
/// Note that dispatching on `Container` instead would be wrong. `Container`
/// paints its colour through one of two different render objects depending on
/// how it was configured, and `Container.color` is only populated on one of
/// them: `color:` builds a `ColoredBox`, while `decoration:` builds a
/// `DecoratedBox` and leaves `color` null. Keying on the widget `Container`
/// actually produces would therefore silently lose every decorated fill.
class ColoredBoxDescriptor extends ElementDescriptor {
  /// Creates the descriptor.
  const ColoredBoxDescriptor();

  @override
  void describeSkeletons(
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {
    final widget = context.element.widget;
    if (widget is! ColoredBox) {
      return;
    }

    // The widget is only consulted if the render object stops exposing the
    // getter. `ColoredBox` forwards its colour to the render object unchanged,
    // so the two agree today; that is a property of this widget alone and is
    // not a pattern to repeat elsewhere.
    final renderObject = context.renderObject;
    final color =
        readUnnameable<Color>(() => (renderObject as dynamic).color as Color) ??
        widget.color;

    if (color.a == 0) {
      return;
    }

    into.add(WireframeSkeleton(rect: context.rect, color: color));
  }
}

/// Average colour of [gradient], or null when it has no colours.
///
/// The wire format carries one colour per rectangle, so a gradient has to
/// collapse to a single value. Stops are ignored deliberately: weighting by
/// them would be more faithful for a lopsided gradient, and wrong in a way that
/// is harder to reason about for every other one, since a stop describes where
/// a colour sits rather than how much area it covers.
Color? _averageColor(Gradient gradient) {
  final colors = gradient.colors;
  if (colors.isEmpty) {
    return null;
  }

  var alpha = 0.0;
  var red = 0.0;
  var green = 0.0;
  var blue = 0.0;
  for (final color in colors) {
    alpha += color.a;
    red += color.r;
    green += color.g;
    blue += color.b;
  }

  final count = colors.length;

  return Color.from(
    alpha: alpha / count,
    red: red / count,
    green: green / count,
    blue: blue / count,
  );
}

/// Appends [side] as a band along one edge of [rect].
void _addSide(
  BorderSide side,
  Rect rect,
  AxisDirection edge,
  List<WireframeSkeleton> into,
) {
  if (side.style == BorderStyle.none || side.width <= 0 || side.color.a == 0) {
    return;
  }

  // Clamped so a border wider than the box it surrounds stays inside it rather
  // than reaching over whatever is next to it.
  final width = side.width.clamp(0.0, rect.width);
  final height = side.width.clamp(0.0, rect.height);

  final band = switch (edge) {
    AxisDirection.up => Rect.fromLTWH(rect.left, rect.top, rect.width, height),
    AxisDirection.down => Rect.fromLTWH(
      rect.left,
      rect.bottom - height,
      rect.width,
      height,
    ),
    AxisDirection.left => Rect.fromLTWH(
      rect.left,
      rect.top,
      width,
      rect.height,
    ),
    AxisDirection.right => Rect.fromLTWH(
      rect.right - width,
      rect.top,
      width,
      rect.height,
    ),
  };

  into.add(WireframeSkeleton(rect: band, color: side.color));
}

/// Appends the four edges of [border] as bands around [rect].
void _addBorder(
  BoxBorder border,
  Rect rect,
  TextDirection? textDirection,
  List<WireframeSkeleton> into,
) {
  final BorderSide left;
  final BorderSide right;
  switch (border) {
    case Border():
      left = border.left;
      right = border.right;
    case BorderDirectional():
      final isRightToLeft = textDirection == TextDirection.rtl;
      left = isRightToLeft ? border.end : border.start;
      right = isRightToLeft ? border.start : border.end;
    default:
      return;
  }

  _addSide(border.top, rect, AxisDirection.up, into);
  _addSide(border.bottom, rect, AxisDirection.down, into);
  _addSide(left, rect, AxisDirection.left, into);
  _addSide(right, rect, AxisDirection.right, into);
}

/// Describes a `DecoratedBox`, the render object behind `Container(decoration:)`
/// and the shape decorations Material uses for cards, chips and inputs.
///
/// Everything is reduced to flat rectangles, which is the only shape the wire
/// format has. A gradient collapses to its average colour, so a gradient
/// background reads as a plausible block rather than as nothing at all, and a
/// border becomes one thin band per edge, which keeps an outlined container from
/// being reported as an empty area.
///
/// Rounded corners, shadows and background images are still lost. Corners and
/// shadows are not expressible as rectangles, and an image's colour is not
/// knowable without decoding it.
class DecoratedBoxDescriptor extends ElementDescriptor {
  /// Creates the descriptor.
  const DecoratedBoxDescriptor();

  @override
  void describeSkeletons(
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {
    final renderObject = context.renderObject;
    if (renderObject is! RenderDecoratedBox) {
      return;
    }

    final rect = context.rect;
    // Taken from the render object rather than from an ancestor lookup, which
    // would register a dependency on an inherited widget during a walk.
    final textDirection = renderObject.configuration.textDirection;

    switch (renderObject.decoration) {
      case final BoxDecoration decoration:
        _addFill(decoration.color, decoration.gradient, rect, into);
        final border = decoration.border;
        if (border != null) {
          _addBorder(border, rect, textDirection, into);
        }

      case final ShapeDecoration decoration:
        _addFill(decoration.color, decoration.gradient, rect, into);
        final shape = decoration.shape;
        if (shape is OutlinedBorder) {
          _addBorder(
            Border.fromBorderSide(shape.side),
            rect,
            textDirection,
            into,
          );
        }
    }
  }

  void _addFill(
    Color? color,
    Gradient? gradient,
    Rect rect,
    List<WireframeSkeleton> into,
  ) {
    final fill = color ?? (gradient == null ? null : _averageColor(gradient));
    if (fill == null || fill.a == 0) {
      return;
    }

    into.add(WireframeSkeleton(rect: rect, color: fill));
  }
}

/// Describes `RenderPhysicalModel` and `RenderPhysicalShape`, the render objects
/// behind `Material` and `PhysicalShape`.
///
/// Both expose `color` through a private common base class. The member itself is
/// public, so it is reachable through the public subclasses.
class PhysicalModelDescriptor extends ElementDescriptor {
  /// Creates the descriptor.
  const PhysicalModelDescriptor();

  @override
  void describeSkeletons(
    DescriptorContext context,
    List<WireframeSkeleton> into,
  ) {
    final renderObject = context.renderObject;
    final Color color;
    if (renderObject is RenderPhysicalModel) {
      color = renderObject.color;
    } else if (renderObject is RenderPhysicalShape) {
      color = renderObject.color;
    } else {
      return;
    }

    if (color.a == 0) {
      return;
    }

    into.add(WireframeSkeleton(rect: context.rect, color: color));
  }
}

/// Describes `RenderOpacity`, propagating its opacity to the captured node.
class OpacityDescriptor extends ElementDescriptor {
  /// Creates the descriptor.
  const OpacityDescriptor();

  @override
  double describeOpacity(DescriptorContext context) {
    final renderObject = context.renderObject;

    return renderObject is RenderOpacity ? renderObject.opacity : 1.0;
  }
}

/// Describes `RenderAnimatedOpacity`, used by `FadeTransition`.
///
/// The animated variant drives opacity from an `Animation` that it listens to
/// directly, without rebuilding the widget. Reading the widget would therefore
/// report a stale value mid-transition; the current value only exists here.
class AnimatedOpacityDescriptor extends ElementDescriptor {
  /// Creates the descriptor.
  const AnimatedOpacityDescriptor();

  @override
  double describeOpacity(DescriptorContext context) {
    final renderObject = context.renderObject;

    return renderObject is RenderAnimatedOpacity
        ? renderObject.opacity.value
        : 1.0;
  }
}
