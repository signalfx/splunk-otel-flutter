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

const Color _ink = Color(0xFFFF5722);

/// Every skeleton in the subtree, flattened.
List<WireframeSkeleton> _skeletons(WireframeNode node) => <WireframeSkeleton>[
  ...node.skeletons,
  for (final child in node.children) ..._skeletons(child),
];

/// Skeletons painted in [color].
///
/// Compared as packed values rather than with `==`, because a colour that has
/// been through a [Paint] comes back reconstructed from floating point channels
/// and no longer equals the constant it was set from.
List<WireframeSkeleton> _fills(WireframeNode node, Color color) => _skeletons(
  node,
).where((skeleton) => skeleton.color.toARGB32() == color.toARGB32()).toList();

/// A host that contributes no skeletons of its own.
///
/// A transparent `Material` rather than a `Scaffold`, because Material controls
/// refuse to build without one but a `Scaffold` would paint a background over
/// the whole view. The debug banner is off because it is itself a painter and
/// would otherwise appear in every capture here.
Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Material(
    type: MaterialType.transparency,
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

/// Counts how many times it is asked to paint.
class _CountingPainter extends CustomPainter {
  _CountingPainter({required this.color});

  final Color color;
  int paintCount = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paintCount++;
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Fails the way an application painter assuming a real canvas would.
class _ThrowingPainter extends CustomPainter {
  const _ThrowingPainter();

  @override
  void paint(Canvas canvas, Size size) => throw StateError('no canvas');

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Draws through a transform and saved state, to check both are followed.
class _NestedPainter extends CustomPainter {
  const _NestedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(10, 20)
      ..drawRect(const Rect.fromLTWH(0, 0, 30, 40), Paint()..color = _ink)
      ..restore()
      // Outside the save, so unaffected by the translate above.
      ..drawRect(const Rect.fromLTWH(0, 0, 5, 5), Paint()..color = _ink);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Draws a ring, the shape a progress indicator and a chart axis are made of.
class _RingPainter extends CustomPainter {
  const _RingPainter();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(
    size.center(Offset.zero),
    40,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = _ink,
  );

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Halves the opacity of everything drawn inside the layer.
class _LayeredPainter extends CustomPainter {
  const _LayeredPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..saveLayer(Offset.zero & size, Paint()..color = const Color(0x80000000))
      ..drawRect(const Rect.fromLTWH(0, 0, 20, 20), Paint()..color = _ink)
      ..restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WireframeWalker walker;

  setUp(() => walker = WireframeWalker());

  group('CustomPaintDescriptor', () {
    testWidgets('should record what a painter draws', (tester) async {
      await tester.pumpWidget(
        _host(
          CustomPaint(
            size: const Size(100, 60),
            painter: _CountingPainter(color: _ink),
          ),
        ),
      );

      final fills = _fills(walker.capture().single.root, _ink);

      expect(fills, hasLength(1));
      expect(fills.single.rect, const Rect.fromLTWH(0, 0, 100, 60));
    });

    testWidgets('should follow transforms and saved state', (tester) async {
      await tester.pumpWidget(
        _host(
          const CustomPaint(size: Size(100, 100), painter: _NestedPainter()),
        ),
      );

      final fills = _fills(walker.capture().single.root, _ink);

      expect(fills, hasLength(2));
      expect(fills[0].rect, const Rect.fromLTWH(10, 20, 30, 40));
      expect(
        fills[1].rect,
        const Rect.fromLTWH(0, 0, 5, 5),
        reason: 'the restore should have undone the translate',
      );
    });

    testWidgets('should carry layer opacity into the shapes inside it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CustomPaint(size: Size(50, 50), painter: _LayeredPainter()),
        ),
      );

      final fills = _fills(walker.capture().single.root, _ink);

      expect(fills, hasLength(1));
      expect(fills.single.effectiveOpacity, closeTo(0.5, 0.01));
    });

    testWidgets('should not re-run a painter that reports itself unchanged', (
      tester,
    ) async {
      final painter = _CountingPainter(color: _ink);

      await tester.pumpWidget(
        _host(CustomPaint(size: const Size(50, 50), painter: painter)),
      );

      final afterFrame = painter.paintCount;

      walker.capture();
      final afterFirst = painter.paintCount;
      walker.capture();
      walker.capture();

      expect(
        afterFirst,
        afterFrame + 1,
        reason: 'the first capture has to record it',
      );
      expect(
        painter.paintCount,
        afterFirst,
        reason: 'later captures should reuse the recording',
      );
    });

    testWidgets('should survive a painter that throws', (tester) async {
      await tester.pumpWidget(
        _host(
          const CustomPaint(size: Size(50, 50), painter: _ThrowingPainter()),
        ),
      );

      // Flutter hits the same failure painting the frame; that one belongs to
      // the framework and is cleared so only the recording's is observed.
      expect(tester.takeException(), isStateError);

      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);

      final frames = walker.capture();

      expect(frames, hasLength(1), reason: 'the frame must still be produced');
      expect(errors, hasLength(1));
      expect(errors.single.exception, isStateError);
    });

    testWidgets('should represent a stroked shape as its outline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CustomPaint(size: Size(100, 100), painter: _RingPainter())),
      );

      final fills = _fills(walker.capture().single.root, _ink);

      // A ring drawn as a solid block would hide whatever sits behind it, so
      // the outline is emitted as bands and the middle is left uncovered.
      expect(fills, hasLength(4));
      for (final fill in fills) {
        expect(
          fill.rect.contains(const Offset(50, 50)),
          isFalse,
          reason: '${fill.rect} fills the middle of the ring',
        );
      }
    });

    group('Material controls', () {
      /// Material paints these entirely through private painters, so before
      /// recording they contributed no appearance at all.
      Future<int> skeletonCount(WidgetTester tester, Widget control) async {
        await tester.pumpWidget(_host(control));

        return _skeletons(walker.capture().single.root).length;
      }

      testWidgets('should contribute nothing for an empty host', (
        tester,
      ) async {
        // Establishes that the counts below come from the control rather than
        // from the surrounding application.
        expect(await skeletonCount(tester, const SizedBox(width: 40)), 0);
      });

      testWidgets('should capture a Switch', (tester) async {
        expect(
          await skeletonCount(tester, Switch(value: true, onChanged: (_) {})),
          greaterThan(0),
        );
      });

      testWidgets('should capture a Checkbox', (tester) async {
        expect(
          await skeletonCount(tester, Checkbox(value: true, onChanged: (_) {})),
          greaterThan(0),
        );
      });

      testWidgets('should capture a Radio', (tester) async {
        expect(
          await skeletonCount(
            tester,
            RadioGroup<int>(
              groupValue: 1,
              onChanged: (_) {},
              child: const Radio<int>(value: 1),
            ),
          ),
          greaterThan(0),
        );
      });

      testWidgets('should capture a LinearProgressIndicator', (tester) async {
        expect(
          await skeletonCount(
            tester,
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(value: 0.5),
            ),
          ),
          greaterThan(0),
        );
      });

      testWidgets('should capture a CircularProgressIndicator', (tester) async {
        expect(
          await skeletonCount(
            tester,
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(value: 0.5),
            ),
          ),
          greaterThan(0),
        );
      });
    });
  });
}
