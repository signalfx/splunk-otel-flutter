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

/// Pins the identity a node carries between frames.
///
/// A node identifier is what lets a consumer follow the same thing from one
/// frame to the next, so what it promises has to be written down. It follows
/// Flutter's own element identity rather than inventing a second one: two
/// frames agree about a node exactly when Flutter kept the same element, which
/// is the same rule that decides whether state is preserved.
///
/// These tests exist to make a change in that behaviour visible, not because
/// every outcome below is desirable.

/// Colour of the row at [index], distinct per row so content can be told apart.
Color _rowColor(int index) => Color(0xFF000010 + index);

/// The node identifier of the first node filled with [color].
String? _idOfFill(WireframeNode node, Color color) {
  for (final skeleton in node.skeletons) {
    if (skeleton.color.toARGB32() == color.toARGB32()) {
      return node.id;
    }
  }
  for (final child in node.children) {
    final found = _idOfFill(child, color);
    if (found != null) {
      return found;
    }
  }

  return null;
}

/// The node carrying [id], if it is in this frame.
WireframeNode? _nodeById(WireframeNode node, String id) {
  if (node.id == id) {
    return node;
  }
  for (final child in node.children) {
    final found = _nodeById(child, id);
    if (found != null) {
      return found;
    }
  }

  return null;
}

Widget _rows(List<int> order, {Key Function(int index)? keyOf}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Column(
    children: <Widget>[
      for (final index in order)
        SizedBox(
          key: keyOf?.call(index),
          width: 200,
          height: 40,
          child: ColoredBox(color: _rowColor(index)),
        ),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('node identity', () {
    testWidgets('should keep the identifier of a row that stays on screen '
        'while a list scrolls', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ListView.builder(
            controller: controller,
            itemExtent: 40,
            itemCount: 100,
            itemBuilder: (context, index) =>
                ColoredBox(color: _rowColor(index)),
          ),
        ),
      );

      final walker = WireframeWalker();
      final before = _idOfFill(walker.capture().single.root, _rowColor(5));

      controller.jumpTo(120);
      await tester.pump();

      final after = _idOfFill(walker.capture().single.root, _rowColor(5));

      expect(before, isNotNull);
      expect(after, before);
    });

    testWidgets('should retire the identifier of a row a list has scrolled '
        'past', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ListView.builder(
            controller: controller,
            itemExtent: 40,
            itemCount: 100,
            itemBuilder: (context, index) =>
                ColoredBox(color: _rowColor(index)),
          ),
        ),
      );

      final walker = WireframeWalker();
      final first = _idOfFill(walker.capture().single.root, _rowColor(0));

      controller.jumpTo(4000);
      await tester.pump();

      final gone = _nodeById(walker.capture().single.root, first!);

      // A lazy list does not recycle elements between indices: a row that
      // leaves the viewport is disposed and a row arriving is built fresh. Its
      // identifier therefore disappears rather than turning up on different
      // content, so a consumer can treat a missing identifier as gone for good.
      expect(gone, isNull);
    });

    testWidgets('should follow keyed children through a reorder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rows(<int>[0, 1, 2], keyOf: (index) => ValueKey<int>(index)),
      );

      final walker = WireframeWalker();
      final before = _idOfFill(walker.capture().single.root, _rowColor(2));

      await tester.pumpWidget(
        _rows(<int>[2, 1, 0], keyOf: (index) => ValueKey<int>(index)),
      );

      final after = _idOfFill(walker.capture().single.root, _rowColor(2));

      expect(before, isNotNull);
      expect(after, before);
    });

    testWidgets('should reuse an identifier for different content when '
        'unkeyed children are reordered', (tester) async {
      await tester.pumpWidget(_rows(<int>[0, 1, 2]));

      final walker = WireframeWalker();
      final firstPosition = _idOfFill(
        walker.capture().single.root,
        _rowColor(0),
      );

      await tester.pumpWidget(_rows(<int>[2, 1, 0]));

      final nowFirstPosition = _idOfFill(
        walker.capture().single.root,
        _rowColor(2),
      );

      // Without a key Flutter reuses the element at each position and only
      // swaps the widget, so identity follows position rather than content.
      // A consumer that must follow content across a reorder needs keys, the
      // same requirement Flutter places on preserving state.
      expect(firstPosition, isNotNull);
      expect(nowFirstPosition, firstPosition);
    });
  });
}
