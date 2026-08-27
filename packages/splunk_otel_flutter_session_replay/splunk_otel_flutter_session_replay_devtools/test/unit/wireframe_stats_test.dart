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

import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay_devtools/splunk_otel_flutter_session_replay_devtools.dart';

void main() {
  group('WireframeStats', () {
    test('should summarise a nested tree', () {
      final root =
          WireframeNode(
            id: 'root',
            type: 'View',
            rect: const Rect.fromLTWH(0, 0, 100, 100),
            skeletons: <WireframeSkeleton>[
              const WireframeSkeleton(
                rect: Rect.fromLTWH(0, 0, 100, 100),
                color: Color(0xFFFFFFFF),
              ),
            ],
          )..addChild(
            WireframeNode(
              id: 'a',
              type: 'ColoredBox',
              rect: const Rect.fromLTWH(0, 0, 50, 50),
              isSensitive: true,
            )..addChild(
              WireframeNode(
                id: 'b',
                type: 'RichText',
                rect: const Rect.fromLTWH(0, 0, 20, 10),
                skeletons: <WireframeSkeleton>[
                  const WireframeSkeleton(
                    rect: Rect.fromLTWH(0, 0, 20, 4),
                    color: Color(0xFF000000),
                    isText: true,
                  ),
                  const WireframeSkeleton(
                    rect: Rect.fromLTWH(0, 6, 15, 4),
                    color: Color(0xFF000000),
                    isText: true,
                  ),
                ],
              ),
            ),
          );

      final stats = WireframeStats.of(
        WireframeFrame(
          viewId: 0,
          capturedAt: DateTime.utc(2026),
          viewSize: const Size(100, 100),
          devicePixelRatio: 1,
          root: root,
        ),
      );

      expect(stats.nodeCount, 3);
      expect(stats.skeletonCount, 3);
      expect(stats.sensitiveNodeCount, 1);
      expect(stats.maxDepth, 2);
    });

    test('should report a lone root as depth zero', () {
      final stats = WireframeStats.of(
        WireframeFrame(
          viewId: 0,
          capturedAt: DateTime.utc(2026),
          viewSize: const Size(10, 10),
          devicePixelRatio: 1,
          root: WireframeNode(
            id: 'root',
            type: 'View',
            rect: const Rect.fromLTWH(0, 0, 10, 10),
          ),
        ),
      );

      expect(stats.nodeCount, 1);
      expect(stats.maxDepth, 0);
      expect(stats.skeletonCount, 0);
    });
  });
}
