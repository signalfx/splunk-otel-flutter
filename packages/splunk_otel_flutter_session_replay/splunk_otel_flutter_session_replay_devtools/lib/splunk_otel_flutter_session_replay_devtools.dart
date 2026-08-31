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

/// Development-only tooling for inspecting Splunk session replay capture.
///
/// Wrap an application in [SessionReplayDebugOverlay] to see what the capture
/// engine produces, drawn back over the running interface.
library;

export 'package:splunk_otel_flutter_session_replay/src/capture/navigation/capture_navigator_observer.dart'
    show CaptureNavigatorObserver;
export 'package:splunk_otel_flutter_session_replay_devtools/src/session_replay_debug_overlay.dart'
    show SessionReplayDebugOverlay;
export 'package:splunk_otel_flutter_session_replay_devtools/src/stream/wireframe_stream_server.dart'
    show StreamServerErrorCallback, WireframeStreamServer;
export 'package:splunk_otel_flutter_session_replay_devtools/src/wireframe_frame_sink.dart'
    show WireframeFrameSink;
export 'package:splunk_otel_flutter_session_replay_devtools/src/wireframe_overlay_painter.dart'
    show WireframeOverlayMode, WireframeOverlayPainter;
export 'package:splunk_otel_flutter_session_replay_devtools/src/wireframe_stats.dart'
    show WireframeStats;
export 'package:splunk_otel_flutter_session_replay_devtools/src/wireframe_tree_explorer.dart'
    show WireframeNodeSelected, WireframeTreeExplorer;
