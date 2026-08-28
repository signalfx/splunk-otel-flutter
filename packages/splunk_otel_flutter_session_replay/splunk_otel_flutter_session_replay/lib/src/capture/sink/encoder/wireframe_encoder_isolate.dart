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
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';

/// Encodes frames to UTF-8 JSON on a long-lived worker isolate.
///
/// Serialising a frame costs several times more than walking the tree for it,
/// and unlike the walk it does not have to happen on the UI thread: a
/// [WireframeFrame] is plain data by the time it reaches here, holding no
/// [Element] or [RenderObject] references, so it can cross an isolate boundary.
///
/// The worker is started once and reused. Spawning per frame would trade the
/// encoding cost for a spawn cost on the very thread this exists to protect.
///
/// Requests are answered in the order they were submitted, because a single
/// worker processes its port sequentially. Callers streaming to a live viewer
/// should still consult [pending] and skip frames rather than queue without
/// bound, since capture can outpace encoding.
class WireframeEncoder {
  /// Creates an encoder. The worker starts on the first [encode].
  WireframeEncoder();

  final Map<int, Completer<Uint8List>> _pending = <int, Completer<Uint8List>>{};

  Isolate? _isolate;
  SendPort? _toWorker;
  ReceivePort? _fromWorker;
  Future<void>? _starting;
  int _nextId = 0;
  bool _disposed = false;

  /// Frames submitted but not yet encoded.
  int get pending => _pending.length;

  /// Encodes [frame] as UTF-8 JSON on the worker.
  Future<Uint8List> encode(WireframeFrame frame) {
    if (_disposed) {
      throw StateError('WireframeEncoder used after dispose');
    }

    // Registered before the first await so that [pending] is accurate the
    // instant this returns. Callers use it to decide whether to submit more
    // work, and a counter that only rises after the worker starts would read
    // as idle during exactly the burst it is meant to report.
    final id = _nextId++;
    final completer = Completer<Uint8List>();
    _pending[id] = completer;
    unawaited(_submit(id, frame));

    return completer.future;
  }

  Future<void> _submit(int id, WireframeFrame frame) async {
    try {
      await (_starting ??= _start());

      // dispose may have run while the worker was starting.
      final worker = _toWorker;
      if (_disposed || worker == null) {
        throw StateError('WireframeEncoder used after dispose');
      }

      worker.send(<Object?>[id, frame]);
    } catch (error) {
      _pending
          .remove(id)
          ?.completeError(error is StateError ? error : StateError('$error'));
    }
  }

  Future<void> _start() async {
    final fromWorker = ReceivePort();
    _fromWorker = fromWorker;

    final handshake = Completer<SendPort>();
    fromWorker.listen((dynamic message) {
      final parts = message as List<Object?>;
      if (parts.length == 1) {
        handshake.complete(parts.single! as SendPort);

        return;
      }

      _complete(parts);
    });

    _isolate = await Isolate.spawn(
      _encodeWorker,
      fromWorker.sendPort,
      debugName: 'splunk-wireframe-encoder',
      errorsAreFatal: false,
    );
    _toWorker = await handshake.future;
  }

  void _complete(List<Object?> parts) {
    final completer = _pending.remove(parts[0] as int);
    if (completer == null) {
      return;
    }

    final error = parts[2] as String?;
    if (error != null) {
      completer.completeError(StateError(error));

      return;
    }

    completer.complete(parts[1]! as Uint8List);
  }

  /// Stops the worker and fails any frame still in flight.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;

    // Wait out a start already in progress, otherwise its spawn would outlive
    // this call and leak the isolate.
    final starting = _starting;
    if (starting != null) {
      await starting.catchError((Object _) {});
    }

    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _toWorker = null;
    _fromWorker?.close();
    _fromWorker = null;

    final inFlight = List<Completer<Uint8List>>.of(_pending.values);
    _pending.clear();
    for (final completer in inFlight) {
      completer.completeError(StateError('WireframeEncoder disposed'));
    }
  }
}

/// Worker entry point. Must be top level so it can be spawned.
void _encodeWorker(SendPort toMain) {
  final fromMain = ReceivePort();
  toMain.send(<Object?>[fromMain.sendPort]);

  fromMain.listen((dynamic message) {
    final parts = message as List<Object?>;
    final id = parts[0] as int;
    try {
      final frame = parts[1]! as WireframeFrame;
      toMain.send(<Object?>[id, utf8.encode(jsonEncode(frame.toJson())), null]);
    } catch (error) {
      toMain.send(<Object?>[id, null, error.toString()]);
    }
  });
}
