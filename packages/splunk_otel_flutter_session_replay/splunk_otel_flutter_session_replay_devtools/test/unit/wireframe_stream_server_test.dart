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
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay_devtools/splunk_otel_flutter_session_replay_devtools.dart';

WireframeFrame _frame({int viewId = 0, String rootId = 'root'}) =>
    WireframeFrame(
      viewId: viewId,
      capturedAt: DateTime.utc(2026),
      viewSize: const Size(100, 200),
      devicePixelRatio: 2,
      root: WireframeNode(
        id: rootId,
        type: 'View',
        rect: const Rect.fromLTWH(0, 0, 100, 200),
      ),
    );

void main() {
  group('WireframeStreamServer', () {
    late WireframeStreamServer server;

    setUp(() async {
      // Port zero avoids collisions between concurrently running tests.
      server = WireframeStreamServer(port: 0);
      await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    Future<HttpClientResponse> get(String path, {String? origin}) async {
      final client = HttpClient();
      addTearDown(client.close);
      final request = await client.get('127.0.0.1', server.boundPort!, path);
      if (origin != null) {
        request.headers.set(WireframeStreamServer.originHeader, origin);
      }

      return request.close();
    }

    Future<WebSocket> connect({String? origin}) => WebSocket.connect(
      'ws://127.0.0.1:${server.boundPort}/ws',
      headers: <String, Object>{
        if (origin != null) WireframeStreamServer.originHeader: origin,
      },
    );

    test('should bind to loopback by default', () {
      expect(server.isRunning, isTrue);
      expect(server.host, WireframeStreamServer.loopbackHost);
      expect(
        server.playerUri.toString(),
        'http://127.0.0.1:${server.boundPort}/',
      );
    });

    test('should serve the player without caching it', () async {
      final response = await get('/');

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'text/html');
      expect(
        response.headers.value(HttpHeaders.cacheControlHeader),
        'no-store',
      );
      expect(
        await response.transform(utf8.decoder).join(),
        contains('<canvas'),
      );
    });

    test('should refuse unknown paths', () async {
      final response = await get('/secrets');

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('should broadcast frames to connected clients', () async {
      final socket = await connect();
      addTearDown(socket.close);
      final received = socket.cast<String>().map(jsonDecode).take(1).toList();

      server.onFrame(_frame());

      final payload = (await received).single as Map<String, Object?>;
      expect(payload['viewId'], 0);
      expect(payload['devicePixelRatio'], 2);
      expect((payload['tree']! as Map<String, Object?>)['id'], 'root');
    });

    test('should supersede a frame still waiting to be encoded', () async {
      // Encoding happens on a worker, so a burst of captures can arrive while
      // one frame is still in flight. The newest must win: dropping the
      // incoming frame instead would leave the viewer on a stale screen.
      final socket = await connect();
      addTearDown(socket.close);
      final received = socket
          .cast<String>()
          .map((message) => jsonDecode(message)! as Map<String, Object?>)
          .take(2)
          .toList();

      server
        ..onFrame(_frame(rootId: 'first'))
        ..onFrame(_frame(rootId: 'superseded'))
        ..onFrame(_frame(rootId: 'newest'));

      final ids = (await received)
          .map((payload) => (payload['tree']! as Map<String, Object?>)['id'])
          .toList();

      // 'first' reached the worker immediately; 'superseded' never did.
      expect(ids, <String>['first', 'newest']);
      expect(server.droppedFrames, 1);
    });

    test('should send the newest frame per view on connect', () async {
      // A client joining a still screen would otherwise see nothing until
      // something on that screen happened to change.
      server
        ..onFrame(_frame(rootId: 'stale'))
        ..onFrame(_frame(rootId: 'fresh'))
        ..onFrame(_frame(viewId: 1, rootId: 'second-view'));

      final socket = await connect();
      addTearDown(socket.close);

      final payloads = await socket
          .cast<String>()
          .map((message) => jsonDecode(message)! as Map<String, Object?>)
          .take(2)
          .toList();
      final ids = payloads
          .map((payload) => (payload['tree']! as Map<String, Object?>)['id'])
          .toList();

      expect(ids, containsAll(<String>['fresh', 'second-view']));
      expect(ids, isNot(contains('stale')));
    });

    test('should drop clients that disconnect', () async {
      final socket = await connect();
      expect(server.clientCount, 1);

      await socket.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(server.clientCount, 0);
    });

    group('exposure', () {
      test('should refuse a socket opened by another origin', () async {
        // A page the user is merely visiting must not be able to read the
        // application interface out of a debug build.
        await expectLater(
          connect(origin: 'http://evil.example'),
          throwsA(isA<WebSocketException>()),
        );
      });

      test('should accept a socket from the page it served', () async {
        final socket = await connect(
          origin: 'http://127.0.0.1:${server.boundPort}',
        );
        addTearDown(socket.close);

        expect(server.clientCount, 1);
      });

      test('should refuse a Host that is not a literal address', () async {
        // DNS rebinding: a domain pointed at loopback still arrives with its
        // own name in the Host header.
        final client = HttpClient();
        addTearDown(client.close);
        final request = await client.get('127.0.0.1', server.boundPort!, '/');
        request.headers.set(
          HttpHeaders.hostHeader,
          'rebind.example:${server.boundPort}',
        );

        final response = await request.close();

        expect(response.statusCode, HttpStatus.forbidden);
      });
    });

    test('should stop cleanly and refuse further connections', () async {
      final port = server.boundPort!;

      await server.stop();

      expect(server.isRunning, isFalse);
      expect(server.playerUri, isNull);
      await expectLater(
        WebSocket.connect('ws://127.0.0.1:$port/ws'),
        throwsA(isA<SocketException>()),
      );

      // The tearDown stop() must tolerate being called twice.
    });
  });
}
