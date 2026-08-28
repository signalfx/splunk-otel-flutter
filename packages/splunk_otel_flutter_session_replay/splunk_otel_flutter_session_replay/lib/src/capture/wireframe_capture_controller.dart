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
import 'dart:developer' show Timeline;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/widgets.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/sink/wireframe_sink.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

/// Signature for capture error reporting.
typedef WireframeCaptureErrorCallback =
    void Function(Object error, StackTrace stackTrace);

/// Drives wireframe capture and fans frames out to registered sinks.
///
/// Capture is paced by a timer rather than by a frame callback. Walking the
/// tree from inside a frame callback would add the walk to the frame budget;
/// running it from a timer lets the scheduler place the work between frames
/// instead. The timer only does work when a frame has actually been built since
/// the last capture, so an idle application costs nothing beyond the tick.
class WireframeCaptureController {
  /// Creates a controller capturing at most once per [interval].
  WireframeCaptureController({
    WireframeWalker? walker,
    this.interval = const Duration(milliseconds: 100),
    this.maxConsecutiveErrors = 3,
    this.onError,
  }) : walker = walker ?? WireframeWalker(),
       assert(
         maxConsecutiveErrors > 0,
         'maxConsecutiveErrors must be positive',
       );

  /// Tree walker producing the frames.
  final WireframeWalker walker;

  /// Minimum delay between two captures.
  final Duration interval;

  /// Number of back-to-back failures tolerated before capture shuts itself off.
  ///
  /// A persistently failing walk would otherwise repeat the same error every
  /// tick for the lifetime of the application.
  final int maxConsecutiveErrors;

  /// Invoked when a capture fails.
  final WireframeCaptureErrorCallback? onError;

  final List<WireframeSink> _sinks = <WireframeSink>[];

  Timer? _timer;
  bool _frameBuiltSinceLastCapture = false;
  bool _captureInProgress = false;
  int _consecutiveErrors = 0;

  /// Whether capture is currently running.
  bool get isRunning => _timer != null;

  /// Registered sinks.
  Iterable<WireframeSink> get sinks => List<WireframeSink>.unmodifiable(_sinks);

  /// Registers [sink] to receive captured frames.
  void addSink(WireframeSink sink) {
    if (!_sinks.contains(sink)) {
      _sinks.add(sink);
    }
  }

  /// Stops delivering frames to [sink].
  void removeSink(WireframeSink sink) => _sinks.remove(sink);

  /// Begins periodic capture. Does nothing if already running.
  void start() {
    if (isRunning) {
      return;
    }

    _consecutiveErrors = 0;
    // Capture the state as it is now rather than waiting for the next frame,
    // so a static screen still produces an initial snapshot.
    _frameBuiltSinceLastCapture = true;
    _observeNextFrame();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  /// Halts periodic capture. Does nothing if not running.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _frameBuiltSinceLastCapture = false;
  }

  /// Captures immediately, bypassing the timer and the dirty-frame check.
  ///
  /// Exists so that a pull-driven consumer, such as the native recorder asking
  /// for the current wireframe, can reuse the same pipeline as the timer.
  List<WireframeFrame> captureNow() {
    Timeline.startSync('SplunkSessionReplay.capture');
    try {
      final frames = walker.capture();

      // A walk duration only means something next to the size of the tree that
      // produced it. Counting nodes is itself proportional to the tree, so a
      // release build, where nobody is reading a timeline, never pays for it.
      if (!kReleaseMode) {
        Timeline.instantSync(
          'SplunkSessionReplay.captured',
          arguments: <String, Object?>{
            'views': frames.length,
            'nodes': frames.fold<int>(
              0,
              (total, frame) => total + frame.nodeCount,
            ),
          },
        );
      }

      return frames;
    } finally {
      Timeline.finishSync();
    }
  }

  /// Releases the timer and all registered sinks.
  Future<void> dispose() async {
    stop();
    final sinks = List<WireframeSink>.of(_sinks);
    _sinks.clear();
    for (final sink in sinks) {
      await sink.dispose();
    }
  }

  void _observeNextFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameBuiltSinceLastCapture = true;
      if (isRunning) {
        _observeNextFrame();
      }
    });
  }

  void _tick() {
    if (!_frameBuiltSinceLastCapture || _captureInProgress) {
      return;
    }

    _frameBuiltSinceLastCapture = false;
    _captureInProgress = true;
    try {
      final frames = captureNow();
      for (final frame in frames) {
        for (final sink in _sinks) {
          sink.onFrame(frame);
        }
      }
      _consecutiveErrors = 0;
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    } finally {
      _captureInProgress = false;
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _consecutiveErrors += 1;

    final callback = onError;
    if (callback != null) {
      callback(error, stackTrace);
    } else {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'splunk_otel_flutter_session_replay',
          context: ErrorDescription('while capturing a session replay frame'),
        ),
      );
    }

    if (_consecutiveErrors >= maxConsecutiveErrors) {
      stop();
    }
  }
}
