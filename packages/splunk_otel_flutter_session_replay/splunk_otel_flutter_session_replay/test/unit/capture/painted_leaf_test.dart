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
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

const Color _ink = Color(0xFF8BC34A);

/// Every skeleton in the subtree, flattened.
List<WireframeSkeleton> _skeletons(WireframeNode node) => <WireframeSkeleton>[
  ...node.skeletons,
  for (final child in node.children) ..._skeletons(child),
];

/// Skeletons painted in [color], compared as packed values because a colour
/// that has been through a [Paint] no longer equals the constant it came from.
List<WireframeSkeleton> _fills(WireframeNode node, Color color) => _skeletons(
  node,
).where((skeleton) => skeleton.color.toARGB32() == color.toARGB32()).toList();

/// A host that contributes no skeletons of its own.
Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Material(
    type: MaterialType.transparency,
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

/// A render object that paints without exposing what it painted, which is the
/// shape of the Material render objects this tier exists for.
class _RenderOpaqueLeaf extends RenderBox {
  int paintCount = 0;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(const Size(60, 30));

  @override
  void paint(PaintingContext context, Offset offset) {
    paintCount++;
    context.canvas.drawRect(offset & size, Paint()..color = _ink);
  }
}

class _OpaqueLeaf extends LeafRenderObjectWidget {
  const _OpaqueLeaf();

  @override
  RenderBox createRenderObject(BuildContext context) => _RenderOpaqueLeaf();
}

/// Fails the way a render object that assumes a real painting context would.
class _RenderHostileLeaf extends RenderBox {
  int paintCount = 0;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(const Size(20, 20));

  @override
  void paint(PaintingContext context, Offset offset) {
    paintCount++;

    throw StateError('not a real context');
  }
}

class _HostileLeaf extends LeafRenderObjectWidget {
  const _HostileLeaf();

  @override
  RenderBox createRenderObject(BuildContext context) => _RenderHostileLeaf();
}

/// A container whose own paint would draw, to prove containers are left alone.
class _RenderPaintingParent extends RenderProxyBox {
  int paintCount = 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    paintCount++;
    super.paint(context, offset);
  }
}

class _PaintingParent extends SingleChildRenderObjectWidget {
  const _PaintingParent({super.child});

  @override
  RenderBox createRenderObject(BuildContext context) => _RenderPaintingParent();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaintedLeafDescriptor', () {
    testWidgets('should capture a leaf that only paints', (tester) async {
      await tester.pumpWidget(_host(const _OpaqueLeaf()));

      final frame = WireframeWalker().capture().single;

      expect(_fills(frame.root, _ink), hasLength(1));
      expect(_fills(frame.root, _ink).single.rect.size, const Size(60, 30));
    });

    testWidgets('should place the leaf in view coordinates', (tester) async {
      await tester.pumpWidget(
        _host(
          const Padding(
            padding: EdgeInsets.only(left: 40, top: 25),
            child: _OpaqueLeaf(),
          ),
        ),
      );

      final frame = WireframeWalker().capture().single;

      expect(
        _fills(frame.root, _ink).single.rect,
        const Rect.fromLTWH(40, 25, 60, 30),
      );
    });

    testWidgets('should not ask a render object with children to paint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const _PaintingParent(child: SizedBox(width: 10, height: 10))),
      );
      final parent = tester.renderObject<_RenderPaintingParent>(
        find.byType(_PaintingParent),
      );
      final painted = parent.paintCount;

      WireframeWalker().capture();

      expect(parent.paintCount, painted);
    });

    testWidgets('should stop asking a leaf that throws', (tester) async {
      await tester.pumpWidget(_host(const _HostileLeaf()));
      // The framework reports the throw from the real paint pass first.
      tester.takeException();

      final leaf = tester.renderObject<_RenderHostileLeaf>(
        find.byType(_HostileLeaf),
      );
      final painted = leaf.paintCount;
      final walker = WireframeWalker();

      final onError = FlutterError.onError;
      FlutterError.onError = (_) {};
      walker.capture();
      walker.capture();
      FlutterError.onError = onError;

      expect(leaf.paintCount, painted + 1);
    });

    testWidgets('should keep capturing the rest of the frame after a throw', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Column(children: <Widget>[_HostileLeaf(), _OpaqueLeaf()])),
      );
      tester.takeException();

      final onError = FlutterError.onError;
      FlutterError.onError = (_) {};
      final frame = WireframeWalker().capture().single;
      FlutterError.onError = onError;

      expect(_fills(frame.root, _ink), hasLength(1));
    });

    testWidgets('should capture a Slider, which paints without a painter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(width: 200, child: Slider(value: 0.5, onChanged: (_) {})),
        ),
      );

      final frame = WireframeWalker().capture().single;
      final within = _skeletons(frame.root)
          .where(
            (skeleton) =>
                tester.getRect(find.byType(Slider)).overlaps(skeleton.rect),
          )
          .toList();

      // The active track, the inactive track and the thumb, at least.
      expect(within.length, greaterThanOrEqualTo(3));
    });
  });
}
