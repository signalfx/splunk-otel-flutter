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
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

const Color _fill = Color(0xFF2196F3);

/// Every skeleton in the subtree, flattened.
List<WireframeSkeleton> _skeletons(WireframeNode node) => <WireframeSkeleton>[
  ...node.skeletons,
  for (final child in node.children) ..._skeletons(child),
];

/// Skeletons painted with [_fill], which is the content under test.
List<WireframeSkeleton> _fills(WireframeNode node) =>
    _skeletons(node).where((skeleton) => skeleton.color == _fill).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WireframeWalker walker;

  setUp(() => walker = WireframeWalker());

  group('clipping', () {
    testWidgets('should not report list content above its viewport', (
      tester,
    ) async {
      // The bug this exists for: a row scrolled half out of a list used to be
      // reported at its full height, so a replay painted the hidden part over
      // the header sitting above the list.
      final controller = ScrollController(initialScrollOffset: 25);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              const SizedBox(height: 100, width: 800),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: 40,
                  itemExtent: 50,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.all(4),
                    child: ColoredBox(color: _fill),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      final fills = _fills(walker.capture().single.root);

      expect(fills, isNotEmpty, reason: 'list content should be captured');
      expect(
        fills.where((skeleton) => skeleton.rect.top < 100),
        isEmpty,
        reason: 'no list content may be reported above the viewport',
      );
    });

    testWidgets('should trim a partially visible row to the visible part', (
      tester,
    ) async {
      final controller = ScrollController(initialScrollOffset: 25);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              const SizedBox(height: 100, width: 800),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  controller: controller,
                  itemCount: 40,
                  itemExtent: 50,
                  itemBuilder: (context, index) =>
                      const ColoredBox(color: _fill),
                ),
              ),
            ],
          ),
        ),
      );

      final fills = _fills(walker.capture().single.root);
      final viewport = const Rect.fromLTWH(0, 100, 800, 200);

      // Every reported fill has to sit inside the viewport, and the row that
      // straddles the top edge has to survive as its visible remainder rather
      // than disappear.
      for (final rect in fills.map((skeleton) => skeleton.rect)) {
        // Spelled out rather than using Rect.contains, which treats the right
        // and bottom edges as outside and so rejects a flush fill.
        expect(
          rect.left >= viewport.left &&
              rect.top >= viewport.top &&
              rect.right <= viewport.right &&
              rect.bottom <= viewport.bottom,
          isTrue,
          reason: '$rect escapes $viewport',
        );
      }
      expect(
        fills.where((skeleton) => skeleton.rect.top == 100),
        isNotEmpty,
        reason: 'the straddling row should be trimmed, not dropped',
      );
    });

    testWidgets('should confine content to an explicit ClipRect', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: 400,
                  maxHeight: 400,
                  child: ColoredBox(color: _fill),
                ),
              ),
            ),
          ),
        ),
      );

      final fills = _fills(walker.capture().single.root);

      expect(fills, hasLength(1));
      expect(fills.single.rect, const Rect.fromLTWH(0, 0, 100, 100));
    });

    testWidgets('should not clip when clipBehavior is none', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 300,
                    height: 300,
                    child: ColoredBox(color: _fill),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final fills = _fills(walker.capture().single.root);

      // Opting out of clipping is a real Flutter behaviour, so honouring it
      // matters as much as applying the clip elsewhere.
      expect(fills.single.rect, const Rect.fromLTWH(0, 0, 300, 300));
    });

    testWidgets('should discard content positioned outside the view', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 2000,
                top: 2000,
                width: 50,
                height: 50,
                child: ColoredBox(color: _fill),
              ),
            ],
          ),
        ),
      );

      expect(_fills(walker.capture().single.root), isEmpty);
    });
  });
}
