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

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/descriptors/box_descriptors.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/descriptors/custom_paint_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/descriptors/image_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/descriptors/painted_leaf_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/descriptors/paragraph_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/descriptors/platform_view_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/element_descriptor.dart';

/// Teaches the registry about a render object type that cannot be named in
/// source.
///
/// When both the widget and its render object are private, neither can be used
/// as a map key. The way in is a public ancestor: while walking below a widget
/// of the registered type, the first render object satisfying [matches] is
/// assumed to be the private one, and its runtime type is recorded so every
/// later frame resolves it directly.
class AncestorLearner {
  /// Associates [descriptor] with the render object identified by [matches].
  const AncestorLearner({required this.descriptor, required this.matches});

  /// Descriptor to install once the render object is identified.
  final ElementDescriptor descriptor;

  /// Recognises the target render object structurally, typically through an
  /// `is` check against a public supertype or mixin.
  final bool Function(RenderBox renderObject) matches;
}

/// Resolves the descriptor that applies to an element.
///
/// Lookups are keyed on `Type` objects rather than type names because a `Type`
/// survives release-mode obfuscation intact, while `runtimeType.toString()` is
/// rewritten to a meaningless symbol. Resolution proceeds in four tiers, from
/// most to least trustworthy source of truth: the render object's type, the
/// widget's type, a learned pairing, and finally asking a childless render
/// object to paint so its shapes can be observed.
class DescriptorRegistry {
  /// Creates a registry, optionally replacing the built-in tables.
  DescriptorRegistry({
    Map<Type, ElementDescriptor>? renderObjectDescriptors,
    Map<Type, ElementDescriptor>? widgetDescriptors,
    Map<Type, AncestorLearner>? ancestorLearners,
  }) : _renderObjectDescriptors = Map<Type, ElementDescriptor>.of(
         renderObjectDescriptors ?? defaultRenderObjectDescriptors,
       ),
       _widgetDescriptors = Map<Type, ElementDescriptor>.of(
         widgetDescriptors ?? defaultWidgetDescriptors,
       ),
       _ancestorLearners = Map<Type, AncestorLearner>.of(
         ancestorLearners ?? const <Type, AncestorLearner>{},
       );

  /// Tier one: render objects whose type can be named and whose painted state
  /// they own outright.
  static const Map<Type, ElementDescriptor> defaultRenderObjectDescriptors =
      <Type, ElementDescriptor>{
        RenderParagraph: ParagraphDescriptor(),
        RenderDecoratedBox: DecoratedBoxDescriptor(),
        RenderPhysicalModel: PhysicalModelDescriptor(),
        RenderPhysicalShape: PhysicalModelDescriptor(),
        RenderOpacity: OpacityDescriptor(),
        RenderAnimatedOpacity: AnimatedOpacityDescriptor(),
        RenderImage: ImageDescriptor(),
        RenderCustomPaint: CustomPaintDescriptor(),
        PlatformViewRenderBox: PlatformViewDescriptor(),
        RenderAndroidView: PlatformViewDescriptor(),
        RenderUiKitView: PlatformViewDescriptor(),
        RenderAppKitView: PlatformViewDescriptor(),
      };

  /// Tier two: private render objects, dispatched on the public widget that
  /// creates them.
  ///
  /// The widget type only selects the descriptor; the painted values are still
  /// read from the render object, through a dynamic selector when the render
  /// object's class is private but its members are not.
  ///
  /// Entries must name the widget that directly creates the render object, not
  /// a convenience widget that composes it. A composing widget can build
  /// different render objects for different configurations while exposing a
  /// single set of properties, so its properties do not describe what any one
  /// render object painted. `Container` is the canonical example.
  static const Map<Type, ElementDescriptor> defaultWidgetDescriptors =
      <Type, ElementDescriptor>{ColoredBox: ColoredBoxDescriptor()};

  final Map<Type, ElementDescriptor> _renderObjectDescriptors;
  final Map<Type, ElementDescriptor> _widgetDescriptors;
  final Map<Type, AncestorLearner> _ancestorLearners;

  /// Registers a tier three learner beneath [ancestorWidgetType].
  ///
  /// Ships empty: every render object Flutter currently paints through is either
  /// public or reachable via a pass-through widget. It exists for application
  /// and third-party code whose render objects are private on both sides.
  void registerAncestorLearner(
    Type ancestorWidgetType,
    AncestorLearner learner,
  ) {
    _ancestorLearners[ancestorWidgetType] = learner;
  }

  /// Returns the learner armed by [widget], if any.
  AncestorLearner? learnerFor(Widget widget) =>
      _ancestorLearners.isEmpty ? null : _ancestorLearners[widget.runtimeType];

  /// Returns the descriptor for [element], or null if it contributes no paint.
  ///
  /// [pendingLearner] is the learner armed by the nearest matching ancestor.
  /// When it recognises [renderObject], the pairing is memoised so subsequent
  /// frames resolve in tier one.
  ElementDescriptor? resolve(
    Element element,
    RenderBox renderObject, {
    AncestorLearner? pendingLearner,
  }) {
    final byRenderObject = _renderObjectDescriptors[renderObject.runtimeType];
    if (byRenderObject != null) {
      return byRenderObject;
    }

    final byWidget = _widgetDescriptors[element.widget.runtimeType];
    if (byWidget != null) {
      return byWidget;
    }

    if (pendingLearner != null && pendingLearner.matches(renderObject)) {
      _renderObjectDescriptors[renderObject.runtimeType] =
          pendingLearner.descriptor;

      return pendingLearner.descriptor;
    }

    // Tier four: nothing named this render object, so ask it to paint.
    //
    // Restricted to childless render objects, which either draw something
    // themselves or are invisible. A container is excluded because its
    // appearance is its own properties and its children are visited anyway.
    //
    // Deliberately not memoised by type. The same type is a leaf in one place
    // and a container in another, so the question has to be asked per instance.
    return isLeaf(renderObject) ? const PaintedLeafDescriptor() : null;
  }
}
