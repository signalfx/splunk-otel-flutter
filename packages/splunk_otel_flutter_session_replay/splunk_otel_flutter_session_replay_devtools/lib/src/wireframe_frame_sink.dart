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

import 'package:flutter/foundation.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/sink/wireframe_sink.dart';

/// Sink that republishes the most recent frame as a listenable value.
///
/// Holds a [ValueNotifier] rather than being one, because [WireframeSink]
/// disposes asynchronously and [ChangeNotifier] does not; the two `dispose`
/// signatures cannot coexist on one class.
class WireframeFrameSink implements WireframeSink {
  /// The most recently captured frame, or null before the first capture.
  final ValueNotifier<WireframeFrame?> latest = ValueNotifier<WireframeFrame?>(
    null,
  );

  int _frameCount = 0;
  DateTime? _previousCapturedAt;
  Duration? _sincePreviousFrame;

  /// Number of frames received since this sink was created.
  int get frameCount => _frameCount;

  /// Time between the two most recent captures, or null before the second.
  ///
  /// Reflects the true capture cadence rather than the requested interval,
  /// which the controller skips whenever no frame was rendered.
  Duration? get sincePreviousFrame => _sincePreviousFrame;

  @override
  void onFrame(WireframeFrame frame) {
    _frameCount += 1;

    final previous = _previousCapturedAt;
    if (previous != null) {
      _sincePreviousFrame = frame.capturedAt.difference(previous);
    }
    _previousCapturedAt = frame.capturedAt;

    latest.value = frame;
  }

  @override
  Future<void> dispose() async => latest.dispose();
}
