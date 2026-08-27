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

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Summary of one captured frame, for display in the debug panel.
class WireframeStats {
  /// Creates a summary.
  const WireframeStats({
    required this.nodeCount,
    required this.skeletonCount,
    required this.sensitiveNodeCount,
    required this.maxDepth,
  });

  /// Summarises [frame] in a single pass over its tree.
  factory WireframeStats.of(WireframeFrame frame) {
    var nodeCount = 0;
    var skeletonCount = 0;
    var sensitiveNodeCount = 0;
    var maxDepth = 0;

    void visit(WireframeNode node, int depth) {
      nodeCount += 1;
      skeletonCount += node.skeletons.length;
      if (node.isSensitive) {
        sensitiveNodeCount += 1;
      }
      if (depth > maxDepth) {
        maxDepth = depth;
      }

      for (final child in node.children) {
        visit(child, depth + 1);
      }
    }

    visit(frame.root, 0);

    return WireframeStats(
      nodeCount: nodeCount,
      skeletonCount: skeletonCount,
      sensitiveNodeCount: sensitiveNodeCount,
      maxDepth: maxDepth,
    );
  }

  /// Total nodes in the frame, including the view root.
  final int nodeCount;

  /// Total fills across every node.
  final int skeletonCount;

  /// Nodes withheld from capture because they were marked private.
  final int sensitiveNodeCount;

  /// Depth of the deepest node, counting the view root as zero.
  final int maxDepth;
}
