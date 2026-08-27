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

/// Describes a `DecoratedBox` carrying a `BoxDecoration`.
///
/// Only the solid fill is represented. Gradients, images, and borders would each
/// need their own skeleton shape, which the wire format cannot express beyond a
/// flat rectangle.
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

    final decoration = renderObject.decoration;
    if (decoration is! BoxDecoration) {
      return;
    }

    final color = decoration.color;
    if (color == null || color.a == 0) {
      return;
    }

    into.add(WireframeSkeleton(rect: context.rect, color: color));
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
