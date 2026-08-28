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

/// Frame serialisation, moved off the UI thread where the platform allows it.
///
/// Encoding a captured frame costs several times more than capturing it, so it
/// runs on a worker isolate wherever one exists. The web has no worker isolate
/// reachable from Dart, so it falls back to encoding inline; the capture engine
/// stays importable there either way.
library;

export 'package:splunk_otel_flutter_session_replay/src/capture/sink/encoder/wireframe_encoder_inline.dart'
    if (dart.library.io) 'package:splunk_otel_flutter_session_replay/src/capture/sink/encoder/wireframe_encoder_isolate.dart';
