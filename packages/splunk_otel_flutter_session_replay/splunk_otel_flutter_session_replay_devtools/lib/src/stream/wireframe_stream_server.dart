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
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/sink/encoder/wireframe_encoder.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/sink/wireframe_sink.dart';

import 'package:splunk_otel_flutter_session_replay_devtools/src/stream/web_player.dart';

/// Signature for stream server error reporting.
typedef StreamServerErrorCallback =
    void Function(Object error, StackTrace stackTrace);

/// Streams captured frames to a browser over a local WebSocket.
///
/// Serves a self-contained player on `/` and upgrades `/ws` to a WebSocket that
/// receives one JSON message per captured frame. Nothing is buffered for replay
/// beyond the newest frame per view, which is sent on connect so a client that
/// joins a still screen is not left staring at an empty canvas.
///
/// Serving needs a socket, so this is not usable on the web. That costs
/// nothing: this package is developer tooling that never ships inside a
/// consuming application, and the capture engine it inspects stays free of
/// `dart:io` so that applications targeting the web are unaffected.
///
/// ## Exposure
///
/// This streams the application's interface, including any text that capture
/// was not asked to mask, to whoever can reach the port. It is therefore
/// refused outright in release builds, and binds to loopback unless told
/// otherwise.
///
/// Loopback is enough for an iOS simulator, which shares the host's, and for
/// Android over `adb forward tcp:8090 tcp:8090`, which carries the host's port
/// to the device's. Note the direction: `adb reverse` is the opposite, for a
/// device reaching a server on the host. Reaching the device from another
/// machine needs [host] set to a non-loopback address, which puts the interface
/// on the network in the clear; prefer forwarding a port.
///
/// Browser clients are held to same-origin, and to a literal-address `Host`, so
/// that a page the user happens to be visiting cannot open a socket against
/// this server and read the interface out of the application.
class WireframeStreamServer implements WireframeSink {
  /// Creates a server; call [start] to bind it.
  WireframeStreamServer({
    this.port = defaultPort,
    this.host = loopbackHost,
    this.onError,
  });

  /// Port used when none is given.
  static const int defaultPort = 8090;

  /// Address used when none is given.
  static const String loopbackHost = '127.0.0.1';

  /// Request header naming the page a browser is acting for.
  ///
  /// `dart:io` has no constant for it, since it is a request header rather than
  /// one a server normally sets.
  static const String originHeader = 'origin';

  /// Port to listen on. Zero binds to any free port, reported by [boundPort].
  final int port;

  /// Address to listen on.
  ///
  /// Defaults to loopback. Anything else exposes the interface to the network.
  final String host;

  /// Invoked when a connection fails. Failures are otherwise swallowed, since a
  /// browser going away must not disturb the application being inspected.
  final StreamServerErrorCallback? onError;

  final Set<WebSocket> _clients = <WebSocket>{};
  final Map<int, String> _latestByView = <int, String>{};

  final WireframeEncoder _encoder = WireframeEncoder();

  /// Newest frame awaiting encoding, per view.
  final Map<int, WireframeFrame> _waiting = <int, WireframeFrame>{};

  HttpServer? _server;

  bool _draining = false;
  int _droppedFrames = 0;

  /// Whether the server is currently bound.
  bool get isRunning => _server != null;

  /// Port actually bound, which differs from [port] when that was zero.
  int? get boundPort => _server?.port;

  /// Number of connected clients.
  int get clientCount => _clients.length;

  /// Frames superseded before they could be encoded.
  ///
  /// A steadily climbing count means capture is outpacing serialisation, which
  /// a slower capture interval addresses.
  int get droppedFrames => _droppedFrames;

  /// Address a browser on this machine should open, or null when not running.
  Uri? get playerUri {
    final server = _server;
    if (server == null) {
      return null;
    }

    final address = server.address.isLoopback
        ? loopbackHost
        : server.address.host;

    return Uri.parse('http://$address:${server.port}/');
  }

  /// Binds the server. Does nothing if already running.
  ///
  /// Throws [StateError] in release builds, where streaming the interface off
  /// the device is never appropriate.
  Future<void> start() async {
    if (kReleaseMode) {
      throw StateError(
        'WireframeStreamServer streams the application interface in the clear '
        'and must not run in a release build.',
      );
    }

    if (isRunning) {
      return;
    }

    final server = await HttpServer.bind(host, port);
    _server = server;
    server.listen(_handleRequest, onError: _reportError, cancelOnError: false);
  }

  /// Closes every client connection and unbinds the server.
  Future<void> stop() async {
    final server = _server;
    _server = null;
    _latestByView.clear();

    final clients = List<WebSocket>.of(_clients);
    _clients.clear();
    for (final client in clients) {
      await client.close().catchError((_) => null);
    }

    await server?.close(force: true);
  }

  @override
  void onFrame(WireframeFrame frame) {
    // Encoding costs several times more than capturing, so it happens on a
    // worker rather than here on the UI thread. Capture can outrun the worker,
    // so frames wait in a slot per view and a newer frame replaces the one
    // waiting: a live viewer wants the current screen, not a backlog of stale
    // ones. Superseding the pending frame rather than the incoming one is what
    // keeps the newest state from being the one thrown away.
    if (_waiting.remove(frame.viewId) != null) {
      _droppedFrames++;
    }
    _waiting[frame.viewId] = frame;

    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining) {
      return;
    }
    _draining = true;

    try {
      while (_waiting.isNotEmpty) {
        final viewId = _waiting.keys.first;
        final frame = _waiting.remove(viewId)!;

        final Uint8List bytes;
        try {
          bytes = await _encoder.encode(frame);
        } catch (error, stackTrace) {
          // Disposal races a frame already in flight, which is expected.
          if (isRunning) {
            _reportError(error, stackTrace);
          }

          continue;
        }

        _broadcast(frame.viewId, utf8.decode(bytes));
      }
    } finally {
      _draining = false;
    }
  }

  void _broadcast(int viewId, String payload) {
    _latestByView[viewId] = payload;

    for (final client in List<WebSocket>.of(_clients)) {
      try {
        client.add(payload);
      } catch (error, stackTrace) {
        _clients.remove(client);
        _reportError(error, stackTrace);
      }
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _encoder.dispose();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (!_isAllowedHost(request)) {
        await _reject(request, HttpStatus.forbidden, 'Unrecognised Host.');

        return;
      }

      if (WebSocketTransformer.isUpgradeRequest(request)) {
        await _handleUpgrade(request);

        return;
      }

      if (request.method == 'GET' && request.uri.path == '/') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          // The player displays application interface; keep it out of caches.
          ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
          ..write(webPlayerHtml);
        await request.response.close();

        return;
      }

      await _reject(request, HttpStatus.notFound, 'Not found.');
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }
  }

  Future<void> _handleUpgrade(HttpRequest request) async {
    if (request.uri.path != '/ws') {
      await _reject(request, HttpStatus.notFound, 'Not found.');

      return;
    }

    if (!_isSameOrigin(request)) {
      await _reject(request, HttpStatus.forbidden, 'Cross-origin refused.');

      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    _clients.add(socket);

    // A client joining a still screen would otherwise wait for the next change.
    for (final payload in _latestByView.values) {
      socket.add(payload);
    }

    socket.listen(
      null,
      onDone: () => _clients.remove(socket),
      onError: (Object error, StackTrace stackTrace) {
        _clients.remove(socket);
        _reportError(error, stackTrace);
      },
      cancelOnError: true,
    );
  }

  /// Rejects a `Host` that is not a literal address.
  ///
  /// A name that resolves to this machine is the shape of a DNS rebinding
  /// attack, where a page the user is visiting points its own domain at
  /// loopback to reach a server that assumed only local software could.
  static bool _isAllowedHost(HttpRequest request) {
    final value = request.headers.value(HttpHeaders.hostHeader);
    if (value == null) {
      return false;
    }

    final authority = Uri.tryParse('http://$value');
    if (authority == null) {
      return false;
    }

    return authority.host == 'localhost' ||
        InternetAddress.tryParse(authority.host) != null;
  }

  /// Requires a browser's `Origin` to match the host it connected to.
  ///
  /// A missing `Origin` means the client is not a browser, and so is not a page
  /// acting on behalf of some other site.
  static bool _isSameOrigin(HttpRequest request) {
    final origin = request.headers.value(originHeader);
    if (origin == null) {
      return true;
    }

    final value = request.headers.value(HttpHeaders.hostHeader);
    if (value == null) {
      return false;
    }

    final originUri = Uri.tryParse(origin);
    if (originUri == null || !originUri.hasAuthority) {
      return false;
    }

    return originUri.authority == value;
  }

  Future<void> _reject(
    HttpRequest request,
    int statusCode,
    String reason,
  ) async {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.text
      ..write(reason);

    await request.response.close();
  }

  void _reportError(Object error, StackTrace stackTrace) {
    final callback = onError;
    if (callback != null) {
      callback(error, stackTrace);

      return;
    }

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'splunk_otel_flutter_session_replay_devtools',
        context: ErrorDescription('while streaming a session replay frame'),
      ),
    );
  }
}
