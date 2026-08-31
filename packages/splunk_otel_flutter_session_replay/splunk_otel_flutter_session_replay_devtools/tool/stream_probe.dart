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
import 'dart:io';

/// Reads the wireframe stream a running application serves and reports what
/// arrives, so capture can be checked against a device rather than a test.
///
/// Run it while the example application is on a device with the player port
/// forwarded:
///
/// ```sh
/// adb forward tcp:8090 tcp:8090
/// dart run tool/stream_probe.dart 30
/// ```
Future<void> main(List<String> args) async {
  final seconds = args.isEmpty ? 20 : int.parse(args.first);
  final socket = await WebSocket.connect('ws://127.0.0.1:8090/ws');
  final start = DateTime.now();
  final gaps = <String>[];
  final done = Completer<void>();

  DateTime? previous;
  var frames = 0;

  int countNodes(Map<String, dynamic> node) {
    final children = node['children'] as List<dynamic>? ?? const [];

    return children.fold<int>(
      1,
      (total, child) => total + countNodes(child as Map<String, dynamic>),
    );
  }

  socket.listen(
    (dynamic message) {
      final text = message as String;
      final now = DateTime.now();
      final elapsed = now.difference(start).inMilliseconds;
      final gap = previous == null
          ? 0
          : now.difference(previous!).inMilliseconds;
      previous = now;
      frames += 1;

      if (gap > 400) {
        gaps.add('${elapsed}ms: nothing for ${gap}ms');
      }

      final payload = jsonDecode(text) as Map<String, dynamic>;
      final capturedAt = (payload['capturedAt'] as num).toInt() ~/ 1000;
      stdout.writeln(
        'epoch=$capturedAt ${elapsed}ms frame#$frames gap=${gap}ms '
        'bytes=${text.length} nodes=${_nodeCount(payload, countNodes)}',
      );
    },
    onDone: () {
      if (!done.isCompleted) {
        done.complete();
      }
    },
    onError: (Object error) => stdout.writeln('error: $error'),
  );

  Timer(Duration(seconds: seconds), () async {
    await socket.close();
    if (!done.isCompleted) {
      done.complete();
    }
  });

  await done.future;

  stdout.writeln('---');
  stdout.writeln('frames: $frames over ${seconds}s');
  stdout.writeln(gaps.isEmpty ? 'no gaps over 400ms' : 'gaps over 400ms:');
  for (final gap in gaps) {
    stdout.writeln('  $gap');
  }
}

int _nodeCount(
  Map<String, dynamic> payload,
  int Function(Map<String, dynamic>) countNodes,
) {
  final root = payload['tree'] ?? payload;

  return root is Map<String, dynamic> ? countNodes(root) : -1;
}
