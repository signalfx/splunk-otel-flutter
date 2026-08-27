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
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/sink/wireframe_sink.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/wireframe_capture_controller.dart';

class _RecordingSink implements WireframeSink {
  final List<WireframeFrame> frames = <WireframeFrame>[];
  bool disposed = false;

  @override
  void onFrame(WireframeFrame frame) => frames.add(frame);

  @override
  Future<void> dispose() async => disposed = true;
}

class _FailingWalker extends WireframeWalker {
  int callCount = 0;

  @override
  List<WireframeFrame> capture() {
    callCount += 1;

    throw StateError('capture failed');
  }
}

const _interval = Duration(milliseconds: 100);

/// Advances past one capture interval with a frame actually rendered.
///
/// The controller only captures when the application has drawn since the last
/// capture, and `pump` skips drawing entirely unless a frame is scheduled. A
/// bare `pump(_interval)` on an idle tree therefore fires the timer but never
/// re-arms the controller, so driving repeated captures requires scheduling a
/// frame explicitly.
Future<void> _pumpFrameAndTick(WidgetTester tester) async {
  tester.binding.scheduleFrame();

  await tester.pump(_interval);
}

void main() {
  group('WireframeCaptureController', () {
    late WireframeCaptureController controller;
    late _RecordingSink sink;

    setUp(() {
      sink = _RecordingSink();
      controller = WireframeCaptureController(interval: _interval);
      controller.addSink(sink);
    });

    tearDown(() async {
      await controller.dispose();
    });

    group('sinks', () {
      test('should register a sink once', () {
        controller.addSink(sink);

        expect(controller.sinks, hasLength(1));
      });

      test('should remove a registered sink', () {
        controller.removeSink(sink);

        expect(controller.sinks, isEmpty);
      });
    });

    group('lifecycle', () {
      test('should not be running before start', () {
        expect(controller.isRunning, isFalse);
      });

      testWidgets('should report running after start', (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        controller.start();

        expect(controller.isRunning, isTrue);
        controller.stop();
      });

      testWidgets('should report not running after stop', (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        controller.start();
        controller.stop();

        expect(controller.isRunning, isFalse);
      });

      testWidgets('should dispose registered sinks', (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        await controller.dispose();

        expect(sink.disposed, isTrue);
        expect(controller.sinks, isEmpty);
      });
    });

    group('captureNow', () {
      testWidgets('should capture without starting the timer', (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        final frames = controller.captureNow();

        expect(frames, hasLength(1));
        expect(controller.isRunning, isFalse);
      });
    });

    group('periodic capture', () {
      testWidgets('should deliver frames to sinks on tick', (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        controller.start();
        await tester.pump(_interval);

        expect(sink.frames, isNotEmpty);
        controller.stop();
      });

      testWidgets('should not deliver frames after stop', (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        controller.start();
        await tester.pump(_interval);
        final countAfterFirstTick = sink.frames.length;

        controller.stop();
        await tester.pump(_interval * 3);

        expect(sink.frames, hasLength(countAfterFirstTick));
      });

      testWidgets('should capture repeatedly while frames are rendered', (
        tester,
      ) async {
        await tester.pumpWidget(const SizedBox.shrink());

        controller.start();
        await _pumpFrameAndTick(tester);
        await _pumpFrameAndTick(tester);

        expect(sink.frames.length, greaterThanOrEqualTo(2));
        controller.stop();
      });

      testWidgets('should skip ticks while the application is idle', (
        tester,
      ) async {
        await tester.pumpWidget(const SizedBox.shrink());

        controller.start();
        // start() allows one initial snapshot so a static screen is still
        // captured once.
        await tester.pump(_interval);
        final countAfterFirstTick = sink.frames.length;

        // No frame is rendered here, so further ticks must do nothing.
        await tester.pump(_interval * 5);

        expect(countAfterFirstTick, 1);
        expect(sink.frames, hasLength(countAfterFirstTick));
        controller.stop();
      });
    });

    group('error handling', () {
      testWidgets('should report capture errors', (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        final errors = <Object>[];
        final failing = WireframeCaptureController(
          walker: _FailingWalker(),
          interval: _interval,
          onError: (error, _) => errors.add(error),
        );
        addTearDown(failing.dispose);

        failing.start();
        await _pumpFrameAndTick(tester);
        failing.stop();

        expect(errors, isNotEmpty);
        expect(errors.first, isA<StateError>());
      });

      testWidgets('should stop after consecutive failures', (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        final walker = _FailingWalker();
        final failing = WireframeCaptureController(
          walker: walker,
          interval: _interval,
          maxConsecutiveErrors: 2,
          onError: (_, _) {},
        );
        addTearDown(failing.dispose);

        failing.start();
        await _pumpFrameAndTick(tester);
        await _pumpFrameAndTick(tester);
        await _pumpFrameAndTick(tester);

        expect(failing.isRunning, isFalse);
        expect(walker.callCount, 2);
      });
    });
  });
}
