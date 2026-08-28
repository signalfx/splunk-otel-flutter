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
import 'dart:typed_data';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';

/// Encodes frames on the calling thread.
///
/// Selected on platforms without worker isolates, which in practice means the
/// web. Encoding a large frame is not cheap, so a web embedder pays it on the
/// same thread that renders; that is a deliberate trade for keeping the capture
/// engine importable everywhere rather than failing to compile.
class WireframeEncoder {
  /// Creates an encoder.
  WireframeEncoder();

  bool _disposed = false;

  /// Frames accepted but not yet encoded. Always zero here, since [encode]
  /// completes before it returns.
  int get pending => 0;

  /// Encodes [frame] as UTF-8 JSON.
  ///
  /// Throws synchronously after [dispose], matching the worker-backed encoder
  /// so that a use-after-dispose surfaces the same way on every platform.
  Future<Uint8List> encode(WireframeFrame frame) {
    if (_disposed) {
      throw StateError('WireframeEncoder used after dispose');
    }

    return Future<Uint8List>.value(utf8.encode(jsonEncode(frame.toJson())));
  }

  /// Releases the encoder.
  Future<void> dispose() async {
    _disposed = true;
  }
}
