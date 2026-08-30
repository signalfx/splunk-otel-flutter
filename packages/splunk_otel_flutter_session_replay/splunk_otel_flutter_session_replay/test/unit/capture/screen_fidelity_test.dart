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

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

import '../../support/wireframe_replay_renderer.dart';

/// Whole-screen fidelity, measured rather than asserted shape by shape.
///
/// The individual descriptor tests say that each kind of element is described
/// correctly. This says how much of a realistic screen actually comes out
/// right, which is the number that degrades silently when Material changes
/// under us or when a new widget arrives that nothing describes.
///
/// The thresholds are floors with room beneath the measured values, not
/// targets. Text is drawn as blocks by design and antialiased edges never
/// match, so a perfect score is neither achievable nor wanted; the point is to
/// notice a fall.

const Key _boundary = Key('fidelity-boundary');

/// Fraction of pixels that must match across the whole view.
///
/// Measured at 92.6% when written.
const double _minimumOverall = 0.85;

/// Fraction of the pixels that differ from the background that must match.
///
/// The stricter of the two: the background is easy to reproduce and dominates
/// the overall figure, so this is what actually tracks how well the interface
/// itself is described.
///
/// Measured at 60.5% when written. Text keeps this far from 100%: a line of
/// text is deliberately a block, so every gap between glyphs counts as a miss.
/// The floor sits well below the measurement because glyph rasterisation
/// differs between the platforms this runs on.
const double _minimumContent = 0.50;

/// Per-channel difference tolerated before two pixels count as different.
///
/// Wide enough to absorb antialiasing and the rounding that separates a colour
/// folded into a fill from the same colour composited by a layer.
const int _tolerance = 16;

Widget _screen() => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: RepaintBoundary(
    key: _boundary,
    child: Scaffold(
      appBar: AppBar(title: const Text('Fidelity')),
      body: ListView(
        children: <Widget>[
          const Card(
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('A list tile'),
              subtitle: Text('with a subtitle'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('A switch'),
          ),
          CheckboxListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('A checkbox'),
          ),
          Slider(value: 0.4, onChanged: (_) {}),
          const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(value: 0.6),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              children: <Widget>[
                ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                TextButton(onPressed: () {}, child: const Text('Text')),
              ],
            ),
          ),
          const Divider(),
          Container(
            height: 60,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF37474F), width: 2),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF00BCD4), Color(0xFF3F51B5)],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    ),
  ),
);

/// Colour covering most of the screen, taken as the background.
Color _background(Pixels pixels) {
  final counts = <int, int>{};
  for (var y = 0; y < pixels.height; y += 2) {
    for (var x = 0; x < pixels.width; x += 2) {
      final key = pixels.at(x.toDouble(), y.toDouble()).toARGB32();
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }

  var background = 0;
  var seen = 0;
  counts.forEach((color, count) {
    if (count > seen) {
      background = color;
      seen = count;
    }
  });

  return Color(background);
}

bool _alike(Color a, Color b, int tolerance) {
  final left = a.toARGB32();
  final right = b.toARGB32();
  for (var shift = 0; shift <= 24; shift += 8) {
    if ((((left >> shift) & 0xFF) - ((right >> shift) & 0xFF)).abs() >
        tolerance) {
      return false;
    }
  }

  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('whole-screen fidelity', () {
    testWidgets('should reproduce a Material screen', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final WireframeFrame frame = WireframeWalker().capture().single;
      final application = await Pixels.from(
        tester,
        rasterizeApplication(tester, _boundary),
      );
      final replay = await Pixels.from(tester, rasterizeWireframe(frame));

      final background = _background(application);
      var total = 0;
      var matched = 0;
      var content = 0;
      var contentMatched = 0;

      for (var y = 0; y < application.height; y++) {
        for (var x = 0; x < application.width; x++) {
          final expected = application.at(x.toDouble(), y.toDouble());
          final actual = replay.at(x.toDouble(), y.toDouble());
          final alike = _alike(expected, actual, _tolerance);

          total++;
          if (alike) {
            matched++;
          }

          if (!_alike(expected, background, 8)) {
            content++;
            if (alike) {
              contentMatched++;
            }
          }
        }
      }

      final overall = matched / total;
      final contentOnly = contentMatched / content;

      expect(
        overall,
        greaterThanOrEqualTo(_minimumOverall),
        reason:
            'whole-view match fell to ${(overall * 100).toStringAsFixed(1)}%',
      );
      expect(
        contentOnly,
        greaterThanOrEqualTo(_minimumContent),
        reason:
            'match over interface pixels fell to '
            '${(contentOnly * 100).toStringAsFixed(1)}%',
      );
    });
  });
}
