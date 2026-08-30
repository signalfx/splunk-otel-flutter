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

const Color _black = Color(0xFF000000);
const Color _white = Color(0xFFFFFFFF);
const Color _border = Color(0xFF3F51B5);

/// Every skeleton in the subtree, flattened.
List<WireframeSkeleton> _skeletons(WireframeNode node) => <WireframeSkeleton>[
  ...node.skeletons,
  for (final child in node.children) ..._skeletons(child),
];

/// A host contributing no skeletons of its own.
Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Align(alignment: Alignment.topLeft, child: child),
);

Widget _decorated(Decoration decoration) =>
    _host(Container(width: 100, height: 40, decoration: decoration));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WireframeWalker walker;

  setUp(() => walker = WireframeWalker());

  group('DecoratedBoxDescriptor', () {
    testWidgets('should report a solid fill', (tester) async {
      await tester.pumpWidget(_decorated(const BoxDecoration(color: _border)));

      final fills = _skeletons(walker.capture().single.root);

      expect(fills, hasLength(1));
      expect(fills.single.color.toARGB32(), _border.toARGB32());
      expect(fills.single.rect, const Rect.fromLTWH(0, 0, 100, 40));
    });

    testWidgets('should collapse a gradient to its average colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _decorated(
          const BoxDecoration(
            gradient: LinearGradient(colors: <Color>[_black, _white]),
          ),
        ),
      );

      final fills = _skeletons(walker.capture().single.root);

      // Black to white averages to mid grey. Reporting nothing, which is what
      // happened before, left a gradient background as an empty area.
      expect(fills, hasLength(1));
      expect(fills.single.color.toARGB32(), 0xFF808080);
    });

    testWidgets('should report a border as one band per edge', (tester) async {
      await tester.pumpWidget(
        _decorated(BoxDecoration(border: Border.all(color: _border, width: 2))),
      );

      final bands = _skeletons(walker.capture().single.root);

      expect(bands, hasLength(4));
      expect(bands.map((band) => band.rect).toSet(), <Rect>{
        const Rect.fromLTWH(0, 0, 100, 2),
        const Rect.fromLTWH(0, 38, 100, 2),
        const Rect.fromLTWH(0, 0, 2, 40),
        const Rect.fromLTWH(98, 0, 2, 40),
      });
    });

    testWidgets('should leave the middle of an outlined container empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _decorated(BoxDecoration(border: Border.all(color: _border, width: 2))),
      );

      // An outline reported as a solid block would hide everything behind it.
      for (final skeleton in _skeletons(walker.capture().single.root)) {
        expect(skeleton.rect.contains(const Offset(50, 20)), isFalse);
      }
    });

    testWidgets('should omit an invisible side', (tester) async {
      await tester.pumpWidget(
        _decorated(
          const BoxDecoration(
            border: Border(top: BorderSide(color: _border, width: 3)),
          ),
        ),
      );

      final bands = _skeletons(walker.capture().single.root);

      expect(bands, hasLength(1));
      expect(bands.single.rect, const Rect.fromLTWH(0, 0, 100, 3));
    });

    testWidgets('should paint the fill under the border', (tester) async {
      await tester.pumpWidget(
        _decorated(
          BoxDecoration(
            color: _white,
            border: Border.all(color: _border, width: 2),
          ),
        ),
      );

      final skeletons = _skeletons(walker.capture().single.root);

      expect(skeletons, hasLength(5));
      expect(
        skeletons.first.color.toARGB32(),
        _white.toARGB32(),
        reason: 'skeletons are consumed in order, so the fill must come first',
      );
    });

    testWidgets('should resolve a directional border against text direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 100,
                height: 40,
                decoration: const BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: _border, width: 4),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final bands = _skeletons(walker.capture().single.root);

      expect(bands, hasLength(1));
      expect(
        bands.single.rect,
        const Rect.fromLTWH(96, 0, 4, 40),
        reason: 'the start edge is on the right when reading right to left',
      );
    });

    testWidgets('should describe a shape decoration', (tester) async {
      await tester.pumpWidget(
        _decorated(
          const ShapeDecoration(
            color: _white,
            shape: StadiumBorder(side: BorderSide(color: _border, width: 2)),
          ),
        ),
      );

      final skeletons = _skeletons(walker.capture().single.root);

      // Cards, chips and input decorations are shaped rather than boxed, so
      // handling only BoxDecoration left much of Material blank.
      expect(skeletons, hasLength(5));
      expect(skeletons.first.color.toARGB32(), _white.toARGB32());
    });
  });
}
