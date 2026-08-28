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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

/// Walk cost benchmark. Not part of the test suite; run it explicitly:
///
/// ```bash
/// flutter test benchmark/capture_benchmark.dart
/// ```
///
/// It lives outside `test/` so `melos test` does not pay for it, and it reports
/// timings rather than asserting them, since wall-clock thresholds turn into
/// flaky tests on shared CI hardware.

/// Branching factor of the synthetic tree.
const int _breadth = 3;

/// Nesting levels below the root.
const int _depth = 6;

/// Captures timed per configuration, after warm-up.
const int _iterations = 60;

/// Captures discarded before timing, to let the JIT settle.
const int _warmupIterations = 10;

/// Builds a tree that is both wide and deep, with a mix of the element kinds
/// the descriptors handle.
///
/// [Stack] is the nesting element because its children may overlap freely, so
/// the tree can grow arbitrarily large without provoking layout overflow.
Widget _buildTree(int depth, {required bool textLeaves}) {
  if (depth == 0) {
    return textLeaves
        ? const Text('leaf', style: TextStyle(color: Colors.black))
        : const SizedBox(width: 20, height: 12);
  }

  return Stack(
    children: <Widget>[
      for (var i = 0; i < _breadth; i++)
        Opacity(
          opacity: 0.9,
          child: ColoredBox(
            color: const Color(0xFF2196F3),
            child: _buildTree(depth - 1, textLeaves: textLeaves),
          ),
        ),
    ],
  );
}

Future<void> _measure(
  WidgetTester tester,
  String label, {
  required bool textLeaves,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: _buildTree(_depth, textLeaves: textLeaves),
    ),
  );

  final walker = WireframeWalker();

  for (var i = 0; i < _warmupIterations; i++) {
    walker.capture();
  }

  final stopwatch = Stopwatch()..start();
  late List<WireframeFrame> frames;
  for (var i = 0; i < _iterations; i++) {
    frames = walker.capture();
  }
  stopwatch.stop();

  final nodeCount = frames.fold<int>(0, (sum, frame) => sum + frame.nodeCount);
  final microsPerCapture = stopwatch.elapsedMicroseconds / _iterations;

  // Serialisation is timed separately: it is the part that could move to an
  // isolate, so its share of the total is what decides whether that is worth
  // the machinery.
  final toJsonWatch = Stopwatch()..start();
  late Object? tree;
  for (var i = 0; i < _iterations; i++) {
    tree = frames.single.toJson();
  }
  toJsonWatch.stop();

  final encodeWatch = Stopwatch()..start();
  var bytes = 0;
  for (var i = 0; i < _iterations; i++) {
    bytes = jsonEncode(tree).length;
  }
  encodeWatch.stop();

  debugPrint(
    '$label: walk ${microsPerCapture.toStringAsFixed(1)}us, '
    'toJson ${(toJsonWatch.elapsedMicroseconds / _iterations).toStringAsFixed(1)}us, '
    'jsonEncode ${(encodeWatch.elapsedMicroseconds / _iterations).toStringAsFixed(1)}us '
    '-> ${(bytes / 1024).toStringAsFixed(1)}KB, '
    '$nodeCount nodes',
  );
}

void main() {
  testWidgets('wireframe capture throughput', (WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(4000, 4000)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Two leaf kinds, so the cost of the text path is visible on its own
    // rather than buried in the total.
    await _measure(tester, 'text-leaves', textLeaves: true);
    await _measure(tester, 'box-leaves', textLeaves: false);
  });
}
