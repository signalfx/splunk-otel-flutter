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

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// One captured wireframe snapshot for a single Flutter view.
///
/// The capture always emits a complete tree: the `BridgeWireframe` format the
/// native SDK consumes has no incremental representation, so there is no
/// add/remove/update form of this type.
///
/// [root] serializes to the native wire contract exactly. The remaining fields
/// are transport metadata used by the debug tooling, and are carried outside
/// [WireframeNode] so the tree itself stays contract-shaped.
class WireframeFrame {
  /// Creates a snapshot of [root] for the view identified by [viewId].
  const WireframeFrame({
    required this.viewId,
    required this.capturedAt,
    required this.viewSize,
    required this.devicePixelRatio,
    required this.root,
  });

  /// Identifier of the originating `FlutterView`.
  ///
  /// Flutter supports multiple views per application, so frames from different
  /// views interleave on a single sink and must be demultiplexed by this value.
  final int viewId;

  /// When the walk producing this frame ran.
  final DateTime capturedAt;

  /// View size in logical pixels.
  final Size viewSize;

  /// Physical pixels per logical pixel for the originating view.
  final double devicePixelRatio;

  /// Root of the captured tree, in the native wire contract shape.
  final WireframeNode root;

  /// Total number of nodes in this frame.
  int get nodeCount => root.subtreeNodeCount;

  /// Serializes the frame for the debug transport.
  ///
  /// The native path sends `root.toJson()` on its own instead, since it expects
  /// the bare `BridgeWireframe` tree with no envelope.
  Map<String, Object?> toJson() => <String, Object?>{
    'viewId': viewId,
    'capturedAt': capturedAt.microsecondsSinceEpoch,
    'width': viewSize.width,
    'height': viewSize.height,
    'devicePixelRatio': devicePixelRatio,
    'tree': root.toJson(),
  };

  @override
  String toString() =>
      'WireframeFrame(viewId: $viewId, nodes: $nodeCount, size: $viewSize)';
}
