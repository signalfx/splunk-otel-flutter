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

const Color _red = Color(0xFFFF0000);
const Color _blue = Color(0xFF0000FF);
const Color _green = Color(0xFF00FF00);

List<WireframeNode> _flatten(WireframeNode node) => <WireframeNode>[
  node,
  for (final child in node.children) ..._flatten(child),
];

/// Every skeleton in the captured tree, in walk order.
List<WireframeSkeleton> _skeletons(WireframeNode root) => <WireframeSkeleton>[
  for (final node in _flatten(root)) ...node.skeletons,
];

WireframeNode _nodeOfType(WireframeNode root, String type) =>
    _flatten(root).firstWhere((node) => node.type == type);

/// Wraps [child] so the tree has a text direction and the child is measured at
/// its intrinsic size rather than stretched to fill the view.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(alignment: Alignment.topLeft, child: child),
);

void main() {
  late WireframeWalker walker;

  setUp(() {
    walker = WireframeWalker();
  });

  group('ColoredBoxDescriptor', () {
    testWidgets('should emit a fill covering the element', (tester) async {
      await tester.pumpWidget(
        _host(
          const ColoredBox(color: _red, child: SizedBox(width: 40, height: 20)),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.color, _red);
      expect(skeleton.rect, const Rect.fromLTWH(0, 0, 40, 20));
      expect(skeleton.isText, isFalse);
    });

    testWidgets('should skip a fully transparent fill', (tester) async {
      await tester.pumpWidget(
        _host(
          const ColoredBox(
            color: Color(0x00FF0000),
            child: SizedBox(width: 40, height: 20),
          ),
        ),
      );

      expect(_skeletons(walker.capture().single.root), isEmpty);
    });

    testWidgets('should read the colour from the render object, not the '
        'widget', (tester) async {
      // Mutating the render object behind the element's back is the only way to
      // make the two disagree. If the descriptor ever regresses to a widget
      // read, this reports the widget's red instead of the painted blue.
      await tester.pumpWidget(
        _host(
          const ColoredBox(color: _red, child: SizedBox(width: 40, height: 20)),
        ),
      );

      final renderObject =
          tester.renderObject<RenderBox>(find.byType(ColoredBox)) as dynamic;
      renderObject.color = _blue;

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.color, _blue);
    });

    testWidgets('should fold the fill alpha into the reported opacity', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ColoredBox(
            color: Color(0x80FF0000),
            child: SizedBox(width: 40, height: 20),
          ),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.effectiveOpacity, closeTo(0x80 / 0xFF, 0.001));
      expect(skeleton.toJson()['color'], '#ff0000');
    });
  });

  group('DecoratedBoxDescriptor', () {
    testWidgets('should emit the decoration fill colour', (tester) async {
      await tester.pumpWidget(
        _host(
          const DecoratedBox(
            decoration: BoxDecoration(color: _blue),
            child: SizedBox(width: 30, height: 30),
          ),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.color, _blue);
      expect(skeleton.rect, const Rect.fromLTWH(0, 0, 30, 30));
    });

    testWidgets('should emit nothing for a decoration without a colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DecoratedBox(
            decoration: BoxDecoration(),
            child: SizedBox(width: 30, height: 30),
          ),
        ),
      );

      expect(_skeletons(walker.capture().single.root), isEmpty);
    });
  });

  group('Container', () {
    // Container paints through a different render object depending on how it
    // was configured, and Container.color is only set on one of those paths.
    // Both must produce the same fill.
    testWidgets('should capture the fill from the color argument', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(width: 40, height: 20, child: ColoredBox(color: _red)),
        ),
      );

      final fromColoredBox = _skeletons(walker.capture().single.root).single;

      await tester.pumpWidget(
        _host(Container(width: 40, height: 20, color: _red)),
      );

      final fromContainer = _skeletons(walker.capture().single.root).single;

      expect(fromContainer.color, _red);
      expect(fromContainer.rect, fromColoredBox.rect);
    });

    testWidgets('should capture the fill from the decoration argument', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Container(
            width: 40,
            height: 20,
            decoration: const BoxDecoration(color: _red),
          ),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.color, _red);
      expect(skeleton.rect, const Rect.fromLTWH(0, 0, 40, 20));
    });
  });

  group('OpacityDescriptor', () {
    testWidgets('should record the opacity on the node', (tester) async {
      await tester.pumpWidget(
        _host(
          const Opacity(
            opacity: 0.25,
            child: ColoredBox(
              color: _red,
              child: SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );

      final node = _nodeOfType(walker.capture().single.root, 'Opacity');

      expect(node.opacity, 0.25);
      expect(node.toJson()['opacity'], 0.25);
    });

    testWidgets('should leave undecorated nodes fully opaque', (tester) async {
      await tester.pumpWidget(
        _host(
          const ColoredBox(color: _red, child: SizedBox(width: 10, height: 10)),
        ),
      );

      final node = _nodeOfType(walker.capture().single.root, 'ColoredBox');

      expect(node.opacity, 1.0);
      expect(node.toJson().containsKey('opacity'), isFalse);
    });
  });

  group('ParagraphDescriptor', () {
    testWidgets('should emit one text skeleton per line', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Text(
              'first line\nsecond line',
              style: TextStyle(color: _red, fontSize: 14),
            ),
          ),
        ),
      );

      final skeletons = _skeletons(walker.capture().single.root);

      expect(skeletons, hasLength(2));
      expect(skeletons.every((skeleton) => skeleton.isText), isTrue);
      expect(skeletons.every((skeleton) => skeleton.color == _red), isTrue);
      // The second line sits below the first.
      expect(skeletons[1].rect.top, greaterThan(skeletons[0].rect.top));
    });

    testWidgets('should position text relative to the view, not the '
        'paragraph', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: EdgeInsets.only(left: 25, top: 15),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text('hi', style: TextStyle(color: _red, fontSize: 14)),
            ),
          ),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.rect.left, greaterThanOrEqualTo(25));
      expect(skeleton.rect.top, greaterThanOrEqualTo(15));
    });

    testWidgets('should use the style resolved by DefaultTextStyle rather '
        'than the widget', (tester) async {
      // The Text widget carries no style at all here; only the render object
      // knows what colour was actually painted.
      await tester.pumpWidget(
        _host(
          const DefaultTextStyle(
            style: TextStyle(color: _green, fontSize: 14),
            child: Text('inherited'),
          ),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.color, _green);
    });

    testWidgets('should colour each span from its own resolved style', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Text.rich(
              TextSpan(
                text: 'red ',
                style: TextStyle(color: _red, fontSize: 14),
                children: <InlineSpan>[
                  TextSpan(
                    text: 'blue ',
                    style: TextStyle(color: _blue),
                  ),
                  // Inherits red from the enclosing span.
                  TextSpan(text: 'red again'),
                ],
              ),
            ),
          ),
        ),
      );

      final colors = _skeletons(
        walker.capture().single.root,
      ).map((skeleton) => skeleton.color).toList();

      expect(colors, <Color>[_red, _blue, _red]);
    });

    testWidgets('should not mark icon glyphs as text', (tester) async {
      await tester.pumpWidget(
        _host(
          const Text(
            '\u{e88a}',
            style: TextStyle(
              color: _red,
              fontSize: 24,
              fontFamily: 'MaterialIcons',
            ),
          ),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.isText, isFalse);
      expect(skeleton.toJson().containsKey('isText'), isFalse);
    });

    testWidgets('should emit nothing for empty text', (tester) async {
      await tester.pumpWidget(
        _host(const Text('', style: TextStyle(color: _red, fontSize: 14))),
      );

      expect(_skeletons(walker.capture().single.root), isEmpty);
    });
  });
}
