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
import 'package:splunk_otel_flutter_session_replay/src/capture/privacy/sensitive_area.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/excluded_from_capture.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

import '../../support/wireframe_replay_renderer.dart';

/// Compares a captured frame against the pixels the application actually drew.
///
/// Stored golden images are avoided on purpose: they are per-platform, and this
/// suite is written on macOS but runs on Linux in CI, where committed images
/// would fail for reasons that have nothing to do with capture. Rendering both
/// the application and the wireframe inside one test run removes the stored
/// artefact and compares against ground truth instead of against expectations.
const Color _white = Color(0xFFFFFFFF);
const Color _red = Color(0xFFFF0000);
const Color _blue = Color(0xFF0000FF);
const Color _green = Color(0xFF00FF00);

const Key _boundary = Key('capture-boundary');

/// Fills the view with [child] behind an opaque backdrop.
///
/// The backdrop is part of the scene rather than a property of the renderer, so
/// both images agree on the background as well as the content.
Widget _scene(Widget child) => RepaintBoundary(
  key: _boundary,
  child: SizedBox.expand(
    child: ColoredBox(
      color: _white,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(children: <Widget>[child]),
      ),
    ),
  ),
);

Widget _box({
  required Color color,
  required double left,
  required double top,
  required double width,
  required double height,
  Widget? child,
}) => Positioned(
  left: left,
  top: top,
  width: width,
  height: height,
  child: ColoredBox(color: color, child: child),
);

List<WireframeNode> _flatten(WireframeNode node) => <WireframeNode>[
  node,
  for (final child in node.children) ..._flatten(child),
];

/// Compares two colours channel by channel.
///
/// [tolerance] exists for blended pixels only. Flutter composites `Opacity`
/// through a layer alpha while the replay painter folds the same opacity into
/// the fill colour, and the two round a half-value in opposite directions. That
/// is a one-unit artefact of the blend path, not a difference in what was
/// captured, so solid fills are still compared exactly.
void _expectSameColor(
  Color actual,
  Color expected, {
  int tolerance = 0,
  String? reason,
}) {
  final actualBits = actual.toARGB32();
  final expectedBits = expected.toARGB32();

  for (var shift = 0; shift <= 24; shift += 8) {
    expect(
      ((actualBits >> shift) & 0xFF) - ((expectedBits >> shift) & 0xFF),
      inInclusiveRange(-tolerance, tolerance),
      reason: '${reason ?? ''} expected $expected but got $actual',
    );
  }
}

void main() {
  late WireframeWalker walker;

  setUp(() {
    walker = WireframeWalker();
  });

  group('replay fidelity', () {
    testWidgets('should reproduce solid fills pixel for pixel', (tester) async {
      await tester.pumpWidget(
        _scene(
          Positioned.fill(
            child: Stack(
              children: <Widget>[
                _box(color: _red, left: 10, top: 20, width: 100, height: 50),
                _box(color: _blue, left: 150, top: 60, width: 80, height: 40),
              ],
            ),
          ),
        ),
      );

      final frame = walker.capture().single;
      final app = await Pixels.from(
        tester,
        rasterizeApplication(tester, _boundary),
      );
      final replay = await Pixels.from(tester, rasterizeWireframe(frame));

      // Centres of each region, well clear of edges where antialiasing could
      // legitimately differ between the two paint paths.
      for (final point in const <Offset>[
        Offset(60, 45), // inside the red box
        Offset(190, 80), // inside the blue box
        Offset(400, 300), // background
      ]) {
        _expectSameColor(
          replay.at(point.dx, point.dy),
          app.at(point.dx, point.dy),
          reason: 'at $point:',
        );
      }
    });

    testWidgets('should reproduce composited opacity', (tester) async {
      // Opacity is reported per node and has to be accumulated by the consumer,
      // so an off-by-one-level bug here shows up as a visibly wrong blend
      // rather than as a structural difference.
      await tester.pumpWidget(
        _scene(
          const Positioned(
            left: 10,
            top: 20,
            width: 100,
            height: 50,
            child: Opacity(opacity: 0.5, child: ColoredBox(color: _green)),
          ),
        ),
      );

      final frame = walker.capture().single;
      final app = await Pixels.from(
        tester,
        rasterizeApplication(tester, _boundary),
      );
      final replay = await Pixels.from(tester, rasterizeWireframe(frame));

      final blended = app.at(60, 45);

      expect(
        blended,
        isNot(_green),
        reason: 'scene should be blended, not solid',
      );
      _expectSameColor(replay.at(60, 45), blended, tolerance: 1);
    });

    testWidgets('should cover the glyphs it stands in for', (tester) async {
      await tester.pumpWidget(
        _scene(
          const Positioned(
            left: 20,
            top: 30,
            child: Text('balance', style: TextStyle(color: _red, fontSize: 20)),
          ),
        ),
      );

      final frame = walker.capture().single;
      final app = await Pixels.from(
        tester,
        rasterizeApplication(tester, _boundary),
      );
      final replay = await Pixels.from(tester, rasterizeWireframe(frame));

      final textSkeleton = _flatten(frame.root)
          .expand((node) => node.skeletons)
          .singleWhere((skeleton) => skeleton.isText);

      // Text becomes a solid block, so it cannot match the glyphs pixel for
      // pixel. What must hold is that the block sits where the glyphs are.
      expect(
        app.containsColorIn(textSkeleton.rect, _red),
        isTrue,
        reason: 'the application should have drawn glyphs here',
      );
      expect(
        replay.at(textSkeleton.rect.center.dx, textSkeleton.rect.center.dy),
        _red,
      );
    });

    testWidgets('should not reproduce masked content anywhere', (tester) async {
      Widget scene({required bool masked}) {
        const content = Positioned(
          left: 10,
          top: 20,
          width: 100,
          height: 50,
          child: ColoredBox(color: _red),
        );

        return _scene(
          masked
              ? const Positioned.fill(
                  child: SensitiveArea(
                    child: Stack(children: <Widget>[content]),
                  ),
                )
              : content,
        );
      }

      // Captured unmasked first, so the masked expectation cannot pass merely
      // because this scene paints nothing.
      await tester.pumpWidget(scene(masked: false));
      final visible = await Pixels.from(
        tester,
        rasterizeWireframe(walker.capture().single),
      );

      expect(visible.containsColor(_red), isTrue);

      await tester.pumpWidget(scene(masked: true));
      final masked = await Pixels.from(
        tester,
        rasterizeWireframe(walker.capture().single),
      );

      expect(masked.containsColor(_red), isFalse);
    });

    testWidgets('should not reproduce excluded content anywhere', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scene(
          const Positioned(
            left: 10,
            top: 20,
            width: 100,
            height: 50,
            child: ExcludedFromCapture(child: ColoredBox(color: _red)),
          ),
        ),
      );

      final replay = await Pixels.from(
        tester,
        rasterizeWireframe(walker.capture().single),
      );

      expect(replay.containsColor(_red), isFalse);
    });
  });
}
