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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

/// Flattens a captured tree so tests can assert on individual nodes.
List<WireframeNode> _flatten(WireframeNode node) => <WireframeNode>[
  node,
  for (final child in node.children) ..._flatten(child),
];

List<WireframeNode> _nodesOfType(WireframeNode root, String type) =>
    _flatten(root).where((node) => node.type == type).toList();

void main() {
  group('WireframeWalker', () {
    late WireframeWalker walker;

    setUp(() {
      walker = WireframeWalker();
    });

    testWidgets('should capture one frame per view', (tester) async {
      await tester.pumpWidget(const SizedBox(width: 10, height: 10));

      final frames = walker.capture();

      expect(frames, hasLength(1));
    });

    testWidgets('should report the view size and device pixel ratio', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());

      final frame = walker.capture().single;

      expect(
        frame.viewSize,
        tester.view.physicalSize / tester.view.devicePixelRatio,
      );
      expect(frame.devicePixelRatio, tester.view.devicePixelRatio);
      expect(frame.root.rect.topLeft, Offset.zero);
    });

    testWidgets('should capture geometry in logical pixels', (tester) async {
      // A device pixel ratio other than 1 would surface any accidental use of
      // physical pixels, which is the failure mode when the render view is
      // passed to getTransformTo instead of null.
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 100, height: 50),
        ),
      );

      final frame = walker.capture().single;
      final sizedBoxes = _nodesOfType(frame.root, 'SizedBox');

      expect(sizedBoxes, isNotEmpty);
      expect(sizedBoxes.first.rect.width, 100.0);
      expect(sizedBoxes.first.rect.height, 50.0);
    });

    testWidgets('should position nodes relative to the view origin', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Padding(
          padding: EdgeInsets.only(left: 25, top: 15),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      final frame = walker.capture().single;
      final sizedBox = _nodesOfType(frame.root, 'SizedBox').first;

      expect(sizedBox.rect.left, 25.0);
      expect(sizedBox.rect.top, 15.0);
    });

    testWidgets('should skip zero-sized render objects', (tester) async {
      // Align passes loose constraints, so the box can actually collapse to
      // zero. As the direct child of the view it would be forced to fill it.
      await tester.pumpWidget(
        const Align(alignment: Alignment.topLeft, child: SizedBox.shrink()),
      );

      final frame = walker.capture().single;

      expect(_nodesOfType(frame.root, 'SizedBox'), isEmpty);
    });

    testWidgets('should skip offstage subtrees', (tester) async {
      await tester.pumpWidget(
        const Offstage(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      final frame = walker.capture().single;

      expect(_nodesOfType(frame.root, 'SizedBox'), isEmpty);
    });

    testWidgets('should nest nodes following the tree structure', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      final frame = walker.capture().single;
      final padding = _nodesOfType(frame.root, 'Padding').first;

      expect(_nodesOfType(padding, 'SizedBox'), isNotEmpty);
    });

    testWidgets('should keep identifiers stable across captures', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 10, height: 10),
        ),
      );

      final first = _nodesOfType(
        walker.capture().single.root,
        'SizedBox',
      ).first;
      await tester.pump();
      final second = _nodesOfType(
        walker.capture().single.root,
        'SizedBox',
      ).first;

      expect(second.id, first.id);
    });

    testWidgets('should allocate distinct identifiers for distinct elements', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Column(
          children: <Widget>[
            SizedBox(width: 10, height: 10),
            SizedBox(width: 10, height: 10),
          ],
        ),
      );

      final boxes = _nodesOfType(walker.capture().single.root, 'SizedBox');

      expect(boxes, hasLength(2));
      expect(boxes[0].id, isNot(boxes[1].id));
    });
  });
}
