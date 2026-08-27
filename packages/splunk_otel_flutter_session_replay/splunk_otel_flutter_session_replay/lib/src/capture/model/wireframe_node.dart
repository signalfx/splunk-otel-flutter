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

import 'dart:ui';

/// A single filled rectangle contributing to the visual appearance of a
/// [WireframeNode].
///
/// A node carries geometry and hierarchy; skeletons carry paint. A solid
/// container produces one skeleton covering its bounds, while a paragraph
/// produces one skeleton per rendered text line.
class WireframeSkeleton {
  /// Creates a skeleton covering [rect], filled with [color].
  const WireframeSkeleton({
    required this.rect,
    required this.color,
    this.opacity = 1.0,
    this.isText = false,
  });

  /// Bounds in logical pixels, relative to the owning view.
  final Rect rect;

  /// Fill color. Any alpha channel is folded into [effectiveOpacity] on
  /// serialization, because the wire format carries color as `#RRGGBB`.
  final Color color;

  /// Opacity contributed by ancestors, independent of the alpha in [color].
  final double opacity;

  /// Whether this skeleton represents a line of text rather than a solid fill.
  final bool isText;

  /// Combined opacity actually sent over the wire.
  ///
  /// The wire format has no alpha channel in its color string, so a
  /// semi-transparent [color] would otherwise be rendered fully opaque.
  double get effectiveOpacity => opacity * color.a;

  /// Serializes to the Splunk `BridgeWireframe` skeleton contract.
  Map<String, Object?> toJson() {
    final combinedOpacity = effectiveOpacity;

    return <String, Object?>{
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
      'color': _toHexRgb(color),
      if (combinedOpacity != 1.0) 'opacity': combinedOpacity,
      if (isText) 'isText': true,
    };
  }

  static String _toHexRgb(Color color) {
    String channel(double value) =>
        (value * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');

    return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}';
  }
}

/// A node in the captured wireframe tree.
///
/// Mirrors one visually meaningful element of the Flutter tree. Serializes to
/// the Splunk `BridgeWireframe` contract, which the native session replay SDK
/// parses directly, so field names and value types here are a wire contract
/// rather than an internal detail. In particular the geometry fields must
/// serialize as doubles and [nativeViewId] as an int.
///
/// All geometry is in logical pixels relative to the owning view; the native
/// layer applies the device pixel ratio itself.
class WireframeNode {
  /// Creates a node covering [rect].
  WireframeNode({
    required this.id,
    required this.type,
    required this.rect,
    this.opacity = 1.0,
    this.isSensitive = false,
    this.nativeViewId,
    List<WireframeNode>? children,
    List<WireframeSkeleton>? skeletons,
  }) : children = children ?? <WireframeNode>[],
       skeletons = skeletons ?? <WireframeSkeleton>[];

  /// Identifier that remains stable across frames for the same element.
  final String id;

  /// Diagnostic label, normally the widget type name.
  ///
  /// This is derived from `runtimeType.toString()` and is therefore minified in
  /// obfuscated release builds. It is a human-readable label only and must
  /// never be used for dispatch or behavior.
  final String type;

  /// Bounds in logical pixels, relative to the owning view.
  final Rect rect;

  /// Opacity inherited from ancestors.
  final double opacity;

  /// Whether this subtree was masked for privacy.
  final bool isSensitive;

  /// Platform view identifier, when this node hosts an embedded native view.
  final int? nativeViewId;

  /// Child nodes, in paint order.
  final List<WireframeNode> children;

  /// Fills contributing to this node's appearance.
  final List<WireframeSkeleton> skeletons;

  /// Appends [child] in paint order.
  void addChild(WireframeNode child) => children.add(child);

  /// Total number of nodes in this subtree, including this one.
  int get subtreeNodeCount {
    var count = 1;
    for (final child in children) {
      count += child.subtreeNodeCount;
    }

    return count;
  }

  /// Serializes this subtree to the Splunk `BridgeWireframe` contract.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    if (nativeViewId != null) 'nativeViewId': nativeViewId,
    'type': type,
    'left': rect.left,
    'top': rect.top,
    'width': rect.width,
    'height': rect.height,
    if (children.isNotEmpty)
      'children': <Object?>[for (final child in children) child.toJson()],
    if (skeletons.isNotEmpty)
      'skeletons': <Object?>[
        for (final skeleton in skeletons) skeleton.toJson(),
      ],
    if (opacity != 1.0) 'opacity': opacity,
    if (isSensitive) 'isSensitive': true,
  };

  @override
  String toString() =>
      'WireframeNode($type, id: $id, rect: $rect, '
      'children: ${children.length}, skeletons: ${skeletons.length})';
}
