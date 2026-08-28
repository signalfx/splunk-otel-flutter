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

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/descriptor_registry.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/element_descriptor.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/privacy/sensitivity_resolver.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/element_id_allocator.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/excluded_from_capture.dart';

/// State inherited down the walk.
///
/// Carried as a single value so it can be shared unchanged by the common case
/// where an element neither arms a learner nor changes masking.
///
/// [ancestor] is the nearest enclosing render object of any kind, not just the
/// ones that produced a node. Slivers and other non-box render objects emit no
/// node but still sit in the render tree, so skipping them here would compose
/// the wrong transform for everything beneath them.
typedef _WalkState = ({
  AncestorLearner? learner,
  bool isSensitive,
  RenderObject? ancestor,
  Matrix4 ancestorTransform,
});

/// Walks the live Flutter element tree and produces wireframe snapshots.
///
/// The walk is deliberately synchronous from start to finish. Geometry read
/// part-way through a walk that then suspends would be combined with geometry
/// from a later frame, which places nodes at stale positions and, once privacy
/// masking lands, can leak content while the UI is moving. Nothing in this class
/// may become `async`.
///
/// The walker produces one [WireframeFrame] per Flutter view. Views are
/// discovered from the element tree rather than from
/// `RendererBinding.instance.renderViews`, because capture needs the [Element]
/// backing each view in order to allocate a stable identifier for it; the two
/// enumerations describe the same set of views.
class WireframeWalker {
  /// Creates a walker, optionally sharing an existing [idAllocator] or
  /// [registry].
  WireframeWalker({
    ElementIdAllocator? idAllocator,
    DescriptorRegistry? registry,
    this.sensitivityResolver = const SensitivityResolver(),
  }) : idAllocator = idAllocator ?? ElementIdAllocator(),
       registry = registry ?? DescriptorRegistry();

  /// Source of frame-stable node identifiers.
  final ElementIdAllocator idAllocator;

  /// Supplies the descriptor that paints each element.
  ///
  /// Shared across walks so that types learned in one frame stay resolved in
  /// every later frame.
  final DescriptorRegistry registry;

  /// Decides which subtrees must not be captured.
  final SensitivityResolver sensitivityResolver;

  /// Captures one snapshot per attached Flutter view.
  ///
  /// Returns an empty list before the first frame, when no root element exists
  /// yet.
  List<WireframeFrame> capture() {
    final rootElement = WidgetsBinding.instance.rootElement;
    if (rootElement == null) {
      return const <WireframeFrame>[];
    }

    final capturedAt = DateTime.now();
    final viewElements = <RenderObjectElement>[];
    _collectViewElements(rootElement, viewElements);

    final frames = <WireframeFrame>[];
    for (final viewElement in viewElements) {
      final frame = _captureView(viewElement, capturedAt);
      if (frame != null) {
        frames.add(frame);
      }
    }

    return frames;
  }

  /// Collects the element backing each render tree root, without descending
  /// past one.
  ///
  /// A view element starts a separate render tree, so each is captured as its
  /// own frame rather than nested inside another view's tree.
  void _collectViewElements(Element element, List<RenderObjectElement> into) {
    if (element is RenderObjectElement && element.renderObject is RenderView) {
      into.add(element);

      return;
    }

    element.visitChildren((child) => _collectViewElements(child, into));
  }

  WireframeFrame? _captureView(
    RenderObjectElement viewElement,
    DateTime capturedAt,
  ) {
    final renderView = viewElement.renderObject as RenderView;
    if (!renderView.attached || !renderView.hasConfiguration) {
      return null;
    }

    final viewSize = renderView.size;
    final root = WireframeNode(
      id: idAllocator.idFor(viewElement),
      type: 'View',
      rect: Offset.zero & viewSize,
    );

    viewElement.debugVisitOnstageChildren(
      (child) => _walk(child, root, (
        learner: null,
        isSensitive: false,
        ancestor: null,
        ancestorTransform: Matrix4.identity(),
      )),
    );

    return WireframeFrame(
      viewId: renderView.flutterView.viewId,
      capturedAt: capturedAt,
      viewSize: viewSize,
      devicePixelRatio: renderView.configuration.devicePixelRatio,
      root: root,
    );
  }

  void _walk(Element element, WireframeNode parent, _WalkState state) {
    // Tooling interface leaves no trace, unlike a masked subtree which still
    // reports its bounds.
    if (element.widget is ExcludedFromCapture) {
      return;
    }

    final renderObject = element is RenderObjectElement
        ? element.renderObject
        : null;

    // A nested view roots its own render tree and is captured as its own
    // frame; descending here would mix two coordinate spaces.
    if (renderObject is RenderView) {
      return;
    }

    // A learner armed higher up stays armed for the whole subtree; a nearer one
    // takes precedence.
    final learner = registry.learnerFor(element.widget) ?? state.learner;

    final isSensitive = switch (sensitivityResolver.resolve(
      element,
      renderObject,
    )) {
      Sensitivity.sensitive => true,
      Sensitivity.notSensitive => false,
      Sensitivity.inherit => state.isSensitive,
    };

    // An element without a render object leaves the transform chain untouched,
    // so the whole state can be shared when nothing else changed either.
    if (renderObject == null) {
      final childState =
          identical(learner, state.learner) && isSensitive == state.isSensitive
          ? state
          : (
              learner: learner,
              isSensitive: isSensitive,
              ancestor: state.ancestor,
              ancestorTransform: state.ancestorTransform,
            );

      element.debugVisitOnstageChildren(
        (child) => _walk(child, parent, childState),
      );

      return;
    }

    final transform = _transformFor(renderObject, state);
    final childState = (
      learner: learner,
      isSensitive: isSensitive,
      ancestor: renderObject,
      ancestorTransform: transform,
    );

    var target = parent;
    final node = _describe(element, renderObject, transform, childState);
    if (node != null) {
      parent.addChild(node);
      target = node;
    }

    element.debugVisitOnstageChildren(
      (child) => _walk(child, target, childState),
    );
  }

  /// Transform from [renderObject]'s local coordinates into view coordinates.
  ///
  /// Composed as the walk descends rather than by asking each render object to
  /// climb back to the root. `getTransformTo` rebuilds the whole ancestor path
  /// on every call, which makes a full walk cost O(nodes x depth); composing
  /// one step per node makes it O(nodes).
  ///
  /// The result is identical to `getTransformTo(null)`, including its deliberate
  /// omission of the root's own `applyPaintTransform`. That omission is what
  /// keeps coordinates in logical pixels, since `RenderView`'s transform is the
  /// one that scales to physical pixels.
  Matrix4 _transformFor(RenderObject renderObject, _WalkState state) {
    final ancestor = state.ancestor;

    // A direct child of the view starts at the identity, which is where
    // getTransformTo(null) starts once the root is skipped.
    if (ancestor == null) {
      return Matrix4.identity();
    }

    if (identical(renderObject.parent, ancestor)) {
      final transform = Matrix4.copy(state.ancestorTransform);
      ancestor.applyPaintTransform(renderObject, transform);

      return transform;
    }

    // Element parentage and render parentage disagree, which composition
    // assumes they do not. Fall back to the authoritative computation rather
    // than placing the node at a wrong position.
    return renderObject.attached
        ? renderObject.getTransformTo(null)
        : Matrix4.identity();
  }

  /// Builds a node for [element], or returns `null` when it contributes no
  /// geometry.
  ///
  /// Non-box render objects such as slivers produce no node, but their children
  /// are still visited by the caller, since box descendants of a sliver are
  /// visible content.
  WireframeNode? _describe(
    Element element,
    RenderObject renderObject,
    Matrix4 transform,
    _WalkState state,
  ) {
    if (renderObject is! RenderBox) {
      return null;
    }
    if (!renderObject.attached || renderObject.owner == null) {
      return null;
    }
    if (!renderObject.hasSize) {
      return null;
    }

    final size = renderObject.size;
    if (size.isEmpty) {
      return null;
    }

    final rect = MatrixUtils.transformRect(transform, Offset.zero & size);
    if (rect.isEmpty) {
      return null;
    }

    final descriptor = registry.resolve(
      element,
      renderObject,
      pendingLearner: state.learner,
    );

    List<WireframeSkeleton>? skeletons;
    var opacity = 1.0;
    if (descriptor != null) {
      final context = DescriptorContext(
        element: element,
        renderObject: renderObject,
        rect: rect,
        transform: transform,
      );

      // Skeletons are the only part of a node that carries content: colours,
      // text line metrics, image blocks. They are withheld from a masked
      // subtree, while opacity is still reported because it describes how the
      // subtree is composited rather than what is inside it.
      if (!state.isSensitive) {
        skeletons = <WireframeSkeleton>[];
        descriptor.describeSkeletons(context, skeletons);
      }

      opacity = descriptor.describeOpacity(context);
    }

    return WireframeNode(
      id: idAllocator.idFor(element),
      // Diagnostic label only. Minified under obfuscation, never dispatched on.
      type: element.widget.runtimeType.toString(),
      rect: rect,
      opacity: opacity,
      isSensitive: state.isSensitive,
      skeletons: skeletons,
    );
  }
}
