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

import 'package:flutter/material.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';

/// Signature for tree explorer selection changes.
typedef WireframeNodeSelected = void Function(String? nodeId);

/// Scrollable view of a captured wireframe tree.
///
/// Collapse state and selection are keyed on node id, which the capture engine
/// keeps stable for the same element across frames. The view therefore holds
/// its position while frames stream in underneath it, instead of resetting ten
/// times a second.
class WireframeTreeExplorer extends StatefulWidget {
  /// Creates an explorer for [root].
  const WireframeTreeExplorer({
    required this.root,
    required this.selectedNodeId,
    required this.onNodeSelected,
    super.key,
  });

  /// Root of the tree to display.
  final WireframeNode root;

  /// Currently highlighted node, if any.
  final String? selectedNodeId;

  /// Called when the user taps a row.
  final WireframeNodeSelected onNodeSelected;

  @override
  State<WireframeTreeExplorer> createState() => _WireframeTreeExplorerState();
}

class _WireframeTreeExplorerState extends State<WireframeTreeExplorer> {
  final Set<String> _collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    final rows = _flatten(widget.root);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: rows.length,
      itemExtent: 28,
      itemBuilder: (context, index) => _buildRow(rows[index]),
    );
  }

  List<_ExplorerRow> _flatten(WireframeNode root) {
    final rows = <_ExplorerRow>[];

    void visit(WireframeNode node, int depth) {
      rows.add(_ExplorerRow(node: node, depth: depth));
      if (_collapsed.contains(node.id)) {
        return;
      }

      for (final child in node.children) {
        visit(child, depth + 1);
      }
    }

    visit(root, 0);

    return rows;
  }

  Widget _buildRow(_ExplorerRow row) {
    final node = row.node;
    final isSelected = node.id == widget.selectedNodeId;
    final hasChildren = node.children.isNotEmpty;
    final isCollapsed = _collapsed.contains(node.id);

    return InkWell(
      onTap: () => widget.onNodeSelected(isSelected ? null : node.id),
      child: ColoredBox(
        color: isSelected ? const Color(0x33FFEA00) : const Color(0x00000000),
        child: Padding(
          padding: EdgeInsets.only(left: 8 + row.depth * 12.0, right: 8),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 20,
                child: hasChildren
                    ? InkWell(
                        onTap: () => setState(() {
                          if (isCollapsed) {
                            _collapsed.remove(node.id);
                          } else {
                            _collapsed.add(node.id);
                          }
                        }),
                        child: Icon(
                          isCollapsed ? Icons.chevron_right : Icons.expand_more,
                          size: 16,
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Text(
                  node.type,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (node.isSensitive)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.lock, size: 12, color: Color(0xFFFF1744)),
                ),
              if (node.skeletons.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${node.skeletons.length}\u25a0',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '${node.rect.width.toStringAsFixed(0)}'
                  '\u00d7'
                  '${node.rect.height.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplorerRow {
  const _ExplorerRow({required this.node, required this.depth});

  final WireframeNode node;
  final int depth;
}
