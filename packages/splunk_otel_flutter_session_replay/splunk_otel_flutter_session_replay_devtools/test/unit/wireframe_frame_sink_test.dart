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

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay_devtools/splunk_otel_flutter_session_replay_devtools.dart';

WireframeFrame _frameAt(DateTime capturedAt) => WireframeFrame(
  viewId: 0,
  capturedAt: capturedAt,
  viewSize: const Size(10, 10),
  devicePixelRatio: 1,
  root: WireframeNode(
    id: 'root',
    type: 'View',
    rect: const Rect.fromLTWH(0, 0, 10, 10),
  ),
);

void main() {
  group('WireframeFrameSink', () {
    late WireframeFrameSink sink;

    setUp(() {
      sink = WireframeFrameSink();
    });

    test('should start empty', () {
      expect(sink.latest.value, isNull);
      expect(sink.frameCount, 0);
      expect(sink.sincePreviousFrame, isNull);
    });

    test('should publish the most recent frame', () {
      final frame = _frameAt(DateTime.utc(2026));

      sink.onFrame(frame);

      expect(sink.latest.value, same(frame));
      expect(sink.frameCount, 1);
    });

    test('should notify listeners on each frame', () {
      var notifications = 0;
      sink.latest.addListener(() => notifications += 1);

      sink
        ..onFrame(_frameAt(DateTime.utc(2026)))
        ..onFrame(_frameAt(DateTime.utc(2026, 1, 1, 0, 0, 1)));

      expect(notifications, 2);
    });

    test('should measure the gap between consecutive captures', () {
      sink
        ..onFrame(_frameAt(DateTime.utc(2026)))
        ..onFrame(
          _frameAt(DateTime.utc(2026).add(const Duration(milliseconds: 120))),
        );

      // The requested interval is a floor, not a guarantee: capture is skipped
      // whenever no frame was rendered, so the measured gap is what matters.
      expect(sink.sincePreviousFrame, const Duration(milliseconds: 120));
    });
  });
}
