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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/navigation/capture_navigator_observer.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/sink/wireframe_sink.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/wireframe_capture_controller.dart';

const Duration _interval = Duration(milliseconds: 100);

class _RecordingSink implements WireframeSink {
  final List<WireframeFrame> frames = <WireframeFrame>[];

  @override
  void onFrame(WireframeFrame frame) => frames.add(frame);

  @override
  Future<void> dispose() async {}
}

Widget _app(
  GlobalKey<NavigatorState> navigatorKey,
  CaptureNavigatorObserver observer,
) => MaterialApp(
  navigatorKey: navigatorKey,
  navigatorObservers: <NavigatorObserver>[observer],
  home: const Scaffold(body: Text('first')),
);

Route<void> _second() => MaterialPageRoute<void>(
  builder: (_) => const Scaffold(body: Text('second')),
);

/// Counts the drawn blocks in a frame, which grows while two screens overlap.
int _fillCount(WireframeFrame frame) {
  int count(WireframeNode node) => node.children.fold<int>(
    node.skeletons.length,
    (total, child) => total + count(child),
  );

  return count(frame.root);
}

void main() {
  late WireframeCaptureController controller;
  late _RecordingSink sink;
  late GlobalKey<NavigatorState> navigatorKey;
  late CaptureNavigatorObserver observer;

  setUp(() {
    sink = _RecordingSink();
    controller = WireframeCaptureController(interval: _interval);
    controller.addSink(sink);
    navigatorKey = GlobalKey<NavigatorState>();
    observer = CaptureNavigatorObserver(controller);
  });

  tearDown(() async {
    await controller.dispose();
  });

  group('CaptureNavigatorObserver', () {
    testWidgets('should suspend capture for the length of a push', (
      tester,
    ) async {
      await tester.pumpWidget(_app(navigatorKey, observer));

      unawaited(navigatorKey.currentState!.push(_second()));
      await tester.pump();

      expect(controller.isSuspended, isTrue);

      // Halfway through, both screens are on screen at once, which is a state
      // the application is passing through rather than one it is in.
      await tester.pump(const Duration(milliseconds: 150));

      expect(controller.isSuspended, isTrue);

      await tester.pumpAndSettle();

      expect(controller.isSuspended, isFalse);
    });

    testWidgets('should be what keeps both screens out of one frame', (
      tester,
    ) async {
      final detached = CaptureNavigatorObserver();

      await tester.pumpWidget(_app(navigatorKey, detached));
      controller.start();
      await tester.pump(_interval);
      final settled = _fillCount(sink.frames.last);
      sink.frames.clear();

      unawaited(navigatorKey.currentState!.push(_second()));
      for (var elapsed = 0; elapsed < 400; elapsed += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      controller.stop();

      // With nothing holding capture off, the transition is captured, and the
      // frames in the middle of it hold the screen being left and the one
      // arriving at once. That is the state the observer exists to withhold,
      // and it is worth knowing that it is what would otherwise be reported.
      expect(sink.frames, isNotEmpty);
      expect(
        sink.frames.any((frame) => _fillCount(frame) > settled),
        isTrue,
        reason: 'expected a frame holding more than one screen worth of fills',
      );
    });

    testWidgets('should capture nothing between the two screens', (
      tester,
    ) async {
      await tester.pumpWidget(_app(navigatorKey, observer));
      controller.start();
      await tester.pump(_interval);
      sink.frames.clear();

      unawaited(navigatorKey.currentState!.push(_second()));
      for (var elapsed = 0; elapsed < 400; elapsed += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(sink.frames, isEmpty);

      await tester.pumpAndSettle();
      await tester.pump(_interval);

      expect(sink.frames, isNotEmpty);
      controller.stop();
    });

    testWidgets('should suspend capture for the length of a pop', (
      tester,
    ) async {
      await tester.pumpWidget(_app(navigatorKey, observer));
      unawaited(navigatorKey.currentState!.push(_second()));
      await tester.pumpAndSettle();

      navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.isSuspended, isTrue);

      await tester.pumpAndSettle();

      expect(controller.isSuspended, isFalse);
    });

    testWidgets('should resume after a route with no transition', (
      tester,
    ) async {
      await tester.pumpWidget(_app(navigatorKey, observer));

      unawaited(
        navigatorKey.currentState!.push(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, _, _) => const Scaffold(body: Text('instant')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing animates, but the frame in which the stack changes is still
      // withheld, so the suspension has to end on its own.
      expect(controller.isSuspended, isFalse);
    });

    testWidgets('should hold capture off for a whole pop gesture', (
      tester,
    ) async {
      await tester.pumpWidget(_app(navigatorKey, observer));

      observer.didStartUserGesture(_second(), null);
      await tester.pump(const Duration(seconds: 1));

      // A drag has no animation to wait on and the finger decides how long it
      // lasts, so the gesture itself holds the suspension.
      expect(controller.isSuspended, isTrue);

      observer.didStopUserGesture();

      expect(controller.isSuspended, isFalse);
    });

    testWidgets('should wait for the last of two overlapping transitions', (
      tester,
    ) async {
      await tester.pumpWidget(_app(navigatorKey, observer));

      unawaited(navigatorKey.currentState!.push(_second()));
      await tester.pump(const Duration(milliseconds: 50));
      unawaited(navigatorKey.currentState!.push(_second()));
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.isSuspended, isTrue);

      await tester.pumpAndSettle();

      expect(controller.isSuspended, isFalse);
    });

    testWidgets('should do nothing until a controller is attached', (
      tester,
    ) async {
      final detached = CaptureNavigatorObserver();

      await tester.pumpWidget(_app(navigatorKey, detached));
      unawaited(navigatorKey.currentState!.push(_second()));
      await tester.pumpAndSettle();

      // An observer is built with the navigator, which can be well before
      // capture exists, so one with nothing attached has to be harmless.
      expect(controller.isSuspended, isFalse);

      detached.controller = controller;
      unawaited(navigatorKey.currentState!.push(_second()));
      await tester.pump();

      expect(controller.isSuspended, isTrue);

      await tester.pumpAndSettle();

      expect(controller.isSuspended, isFalse);
    });

    testWidgets('should let a replaced route settle', (tester) async {
      await tester.pumpWidget(_app(navigatorKey, observer));

      navigatorKey.currentState!.pushReplacement(_second());
      await tester.pump();

      expect(controller.isSuspended, isTrue);

      await tester.pumpAndSettle();

      expect(controller.isSuspended, isFalse);
    });
  });
}
