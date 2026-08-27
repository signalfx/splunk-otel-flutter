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

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';

/// Destination for captured wireframe frames.
///
/// This is the seam that keeps the capture engine independent of transport: the
/// walker never knows whether it is feeding an in-app debug overlay, a
/// WebSocket connection to a browser, or the native session replay bridge.
///
/// Implementations must return quickly. [onFrame] is invoked synchronously from
/// the capture loop on the UI thread, so any encoding, buffering, or I/O has to
/// be deferred by the implementation rather than awaited here.
abstract interface class WireframeSink {
  /// Called once per captured frame, per view.
  ///
  /// Must not throw; the controller treats a throwing sink as a capture error.
  void onFrame(WireframeFrame frame);

  /// Releases any resources held by this sink.
  Future<void> dispose();
}

/// A [WireframeSink] that retains the most recent frames in memory.
///
/// Used by the debug overlay and by tests. Frames are kept per view so that a
/// multi-view application does not evict one view's frames with another's.
class BufferedWireframeSink implements WireframeSink {
  /// Creates a sink retaining up to [capacity] frames per view.
  BufferedWireframeSink({this.capacity = 120})
    : assert(capacity > 0, 'capacity must be positive');

  /// Maximum number of retained frames per view.
  final int capacity;

  final Map<int, List<WireframeFrame>> _framesByView =
      <int, List<WireframeFrame>>{};

  /// View identifiers seen so far.
  Iterable<int> get viewIds => _framesByView.keys;

  /// Retained frames for [viewId], oldest first.
  List<WireframeFrame> framesForView(int viewId) =>
      List<WireframeFrame>.unmodifiable(
        _framesByView[viewId] ?? const <WireframeFrame>[],
      );

  /// Most recent frame for [viewId], or `null` if none has been captured.
  WireframeFrame? latestForView(int viewId) {
    final frames = _framesByView[viewId];
    if (frames == null || frames.isEmpty) {
      return null;
    }

    return frames.last;
  }

  @override
  void onFrame(WireframeFrame frame) {
    final frames = _framesByView.putIfAbsent(
      frame.viewId,
      () => <WireframeFrame>[],
    );
    frames.add(frame);
    if (frames.length > capacity) {
      frames.removeRange(0, frames.length - capacity);
    }
  }

  /// Drops all retained frames.
  void clear() => _framesByView.clear();

  @override
  Future<void> dispose() async => clear();
}
