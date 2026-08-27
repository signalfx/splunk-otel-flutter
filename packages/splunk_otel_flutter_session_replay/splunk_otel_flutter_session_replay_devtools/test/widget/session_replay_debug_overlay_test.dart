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
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';
import 'package:splunk_otel_flutter_session_replay_devtools/splunk_otel_flutter_session_replay_devtools.dart';

Widget _app({bool enabled = true}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => SessionReplayDebugOverlay(
    enabled: enabled,
    interval: const Duration(milliseconds: 20),
    child: child!,
  ),
  home: const Scaffold(body: Center(child: Text('application content'))),
);

void main() {
  group('SessionReplayDebugOverlay', () {
    testWidgets('should render the application beneath it', (tester) async {
      await tester.pumpWidget(_app());

      expect(find.text('application content'), findsOneWidget);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    });

    testWidgets('should add nothing to the tree when disabled', (tester) async {
      await tester.pumpWidget(_app(enabled: false));

      expect(find.text('application content'), findsOneWidget);
      expect(find.byIcon(Icons.layers_outlined), findsNothing);
    });

    testWidgets('should open the panel when the button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(_app());

      await tester.tap(find.byIcon(Icons.layers_outlined));
      await tester.pump();

      expect(find.text('Session replay'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('should show captured statistics once a frame arrives', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.byIcon(Icons.layers_outlined));
      await tester.pump();

      // Let the capture timer fire and the panel rebuild on the result.
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump();

      expect(find.textContaining('nodes'), findsOneWidget);
      expect(find.text('Waiting for the first capture\u2026'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('should keep its own interface out of the capture', (
      tester,
    ) async {
      final walker = WireframeWalker();
      await tester.pumpWidget(_app());

      final closed = walker.capture().single.root.subtreeNodeCount;

      await tester.tap(find.byIcon(Icons.layers_outlined));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump();

      final open = walker.capture().single.root.subtreeNodeCount;

      // Opening the panel adds a toolbar, a statistics row and a tree view to
      // the widget tree. If any of that reached the capture the count would
      // jump, and the tool would end up recording itself recording.
      expect(open, closed);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
