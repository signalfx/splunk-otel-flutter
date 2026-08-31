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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_frame.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/navigation/capture_navigator_observer.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/excluded_from_capture.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/wireframe_capture_controller.dart';

import 'package:splunk_otel_flutter_session_replay_devtools/src/stream/wireframe_stream_server.dart';
import 'package:splunk_otel_flutter_session_replay_devtools/src/wireframe_frame_sink.dart';
import 'package:splunk_otel_flutter_session_replay_devtools/src/wireframe_overlay_painter.dart';
import 'package:splunk_otel_flutter_session_replay_devtools/src/wireframe_stats.dart';
import 'package:splunk_otel_flutter_session_replay_devtools/src/wireframe_tree_explorer.dart';

/// Wraps an application with an on-device inspector for wireframe capture.
///
/// Install it through [MaterialApp.builder] so that it sits above the
/// navigator and stays mounted across route changes:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => SessionReplayDebugOverlay(child: child!),
///   home: const HomeScreen(),
/// )
/// ```
///
/// The inspector is compiled out of release builds by default, and its own
/// interface is excluded from capture, so what it displays is only ever the
/// application beneath it.
///
/// Capture runs only while something is displaying it. Closing the panel and
/// turning the overlay off stops the walk entirely rather than leaving it
/// running against a hidden consumer.
class SessionReplayDebugOverlay extends StatefulWidget {
  /// Wraps [child] with the inspector.
  const SessionReplayDebugOverlay({
    required this.child,
    this.enabled = kDebugMode,
    this.interval = const Duration(milliseconds: 100),
    this.streamPort,
    this.navigatorObserver,
    super.key,
  });

  /// Application to inspect.
  final Widget child;

  /// Observer to hold capture off with while a route is moving.
  ///
  /// An observer belongs to the navigator, which is built below this widget, so
  /// it is created by the application and handed here to be attached:
  ///
  /// ```dart
  /// final observer = CaptureNavigatorObserver();
  ///
  /// MaterialApp(
  ///   navigatorObservers: [observer],
  ///   builder: (context, child) => SessionReplayDebugOverlay(
  ///     navigatorObserver: observer,
  ///     child: child!,
  ///   ),
  /// );
  /// ```
  final CaptureNavigatorObserver? navigatorObserver;

  /// Whether to install the inspector at all.
  ///
  /// Defaults to debug builds only. When false this widget adds nothing to the
  /// tree beyond a pass-through build.
  final bool enabled;

  /// Requested delay between captures.
  final Duration interval;

  /// Port to serve the browser-based player on, or null to keep capture local.
  ///
  /// Binds to loopback, so reach it from an iOS simulator directly, or from
  /// Android by forwarding the host's port to the device's with
  /// `adb forward tcp:8090 tcp:8090`. The panel shows the resulting address.
  ///
  /// Streaming keeps capture running whether or not the panel is open, since
  /// the browser is a consumer in its own right.
  final int? streamPort;

  @override
  State<SessionReplayDebugOverlay> createState() =>
      _SessionReplayDebugOverlayState();
}

class _SessionReplayDebugOverlayState extends State<SessionReplayDebugOverlay> {
  static const double _buttonSize = 44;
  static const double _panelHeightFraction = 0.45;

  final WireframeFrameSink _sink = WireframeFrameSink();
  late final WireframeCaptureController _controller;

  WireframeOverlayMode _mode = WireframeOverlayMode.off;
  bool _panelOpen = false;
  String? _selectedNodeId;
  Offset? _buttonOffset;
  Timer? _copyFeedbackTimer;
  bool _showCopyFeedback = false;
  WireframeStreamServer? _server;
  String? _streamStatus;

  @override
  void initState() {
    super.initState();
    _controller = WireframeCaptureController(interval: widget.interval)
      ..addSink(_sink);
    widget.navigatorObserver?.controller = _controller;

    if (widget.streamPort != null) {
      unawaited(_startStreaming(widget.streamPort!));
    }
  }

  Future<void> _startStreaming(int port) async {
    final server = WireframeStreamServer(port: port);

    try {
      await server.start();
    } catch (error) {
      if (mounted) {
        setState(() => _streamStatus = 'unavailable: $error');
      }

      return;
    }

    if (!mounted) {
      await server.stop();

      return;
    }

    _controller.addSink(server);
    setState(() {
      _server = server;
      _streamStatus = server.playerUri?.toString();
    });
    _syncCapture();
  }

  @override
  void dispose() {
    _copyFeedbackTimer?.cancel();
    if (identical(widget.navigatorObserver?.controller, _controller)) {
      widget.navigatorObserver?.controller = null;
    }
    // Disposing the controller also disposes the sink it owns.
    unawaited(_controller.dispose());
    super.dispose();
  }

  /// Runs capture only while something is there to consume it.
  void _syncCapture() {
    final isNeeded =
        _mode != WireframeOverlayMode.off || _panelOpen || _server != null;
    if (isNeeded && !_controller.isRunning) {
      _controller.start();

      return;
    }

    if (!isNeeded && _controller.isRunning) {
      _controller.stop();
    }
  }

  void _setMode(WireframeOverlayMode mode) {
    setState(() => _mode = mode);
    _syncCapture();
  }

  void _togglePanel() {
    setState(() => _panelOpen = !_panelOpen);
    _syncCapture();
  }

  Future<void> _copyFrameJson() async {
    final frame = _sink.latest.value;
    if (frame == null) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(frame.toJson()),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => _showCopyFeedback = true);
    _copyFeedbackTimer?.cancel();
    _copyFeedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showCopyFeedback = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        // Everything above this point is the application; everything below is
        // tooling, and must leave no trace in the frames it is inspecting.
        ExcludedFromCapture(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              type: MaterialType.transparency,
              child: LayoutBuilder(builder: _buildTooling),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTooling(BuildContext context, BoxConstraints constraints) {
    final size = constraints.biggest;
    final buttonOffset =
        _buttonOffset ??
        Offset(size.width - _buttonSize - 16, size.height - _buttonSize - 96);

    return Stack(
      alignment: Alignment.topLeft,
      children: <Widget>[
        if (_mode != WireframeOverlayMode.off)
          Positioned.fill(child: IgnorePointer(child: _buildWireframeLayer())),
        if (_panelOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * _panelHeightFraction,
            child: _buildPanel(),
          ),
        Positioned(
          left: buttonOffset.dx.clamp(0.0, size.width - _buttonSize),
          top: buttonOffset.dy.clamp(0.0, size.height - _buttonSize),
          child: _buildButton(size),
        ),
      ],
    );
  }

  Widget _buildWireframeLayer() => ValueListenableBuilder<WireframeFrame?>(
    valueListenable: _sink.latest,
    builder: (context, frame, _) {
      if (frame == null) {
        return const SizedBox.shrink();
      }

      return CustomPaint(
        painter: WireframeOverlayPainter(
          frame: frame,
          mode: _mode,
          highlightedNodeId: _selectedNodeId,
        ),
      );
    },
  );

  Widget _buildButton(Size size) => GestureDetector(
    onPanUpdate: (details) => setState(() {
      final current =
          _buttonOffset ??
          Offset(size.width - _buttonSize - 16, size.height - _buttonSize - 96);
      _buttonOffset = current + details.delta;
    }),
    onTap: _togglePanel,
    child: Container(
      width: _buttonSize,
      height: _buttonSize,
      decoration: BoxDecoration(
        color: _panelOpen ? const Color(0xFF00B0FF) : const Color(0xCC263238),
        shape: BoxShape.circle,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.layers_outlined,
        color: Color(0xFFFFFFFF),
        size: 22,
      ),
    ),
  );

  Widget _buildPanel() => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xFFFAFAFA),
      border: Border(top: BorderSide(color: Color(0xFFBDBDBD))),
    ),
    child: ValueListenableBuilder<WireframeFrame?>(
      valueListenable: _sink.latest,
      builder: (context, frame, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildToolbar(frame),
          _buildStatsBar(frame),
          Expanded(
            child: frame == null
                ? const Center(
                    child: Text(
                      'Waiting for the first capture\u2026',
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                : WireframeTreeExplorer(
                    root: frame.root,
                    selectedNodeId: _selectedNodeId,
                    onNodeSelected: (nodeId) =>
                        setState(() => _selectedNodeId = nodeId),
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _buildToolbar(WireframeFrame? frame) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: <Widget>[
        const Text(
          'Session replay',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        for (final mode in WireframeOverlayMode.values)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _ModeButton(
              mode: mode,
              isSelected: _mode == mode,
              onPressed: () => _setMode(mode),
            ),
          ),
        // No tooltips: this sits above the navigator, where there is no
        // Overlay for a tooltip to mount into.
        IconButton(
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: frame == null ? null : _copyFrameJson,
          icon: Icon(_showCopyFeedback ? Icons.check : Icons.copy),
        ),
        IconButton(
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: _togglePanel,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  Widget _buildStatsBar(WireframeFrame? frame) {
    if (frame == null) {
      return const SizedBox.shrink();
    }

    final stats = WireframeStats.of(frame);
    final sincePrevious = _sink.sincePreviousFrame;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 2,
        children: <Widget>[
          _Stat(label: 'nodes', value: '${stats.nodeCount}'),
          _Stat(label: 'fills', value: '${stats.skeletonCount}'),
          _Stat(label: 'depth', value: '${stats.maxDepth}'),
          _Stat(label: 'private', value: '${stats.sensitiveNodeCount}'),
          _Stat(label: 'frames', value: '${_sink.frameCount}'),
          if (sincePrevious != null)
            _Stat(
              label: 'interval',
              value: '${sincePrevious.inMilliseconds}ms',
            ),
          if (_streamStatus != null)
            _Stat(
              label: 'player',
              value: '$_streamStatus (${_server?.clientCount ?? 0})',
            ),
          _Stat(
            label: 'view',
            value:
                '${frame.viewSize.width.toStringAsFixed(0)}'
                '\u00d7'
                '${frame.viewSize.height.toStringAsFixed(0)} '
                '@${frame.devicePixelRatio}x',
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.isSelected,
    required this.onPressed,
  });

  final WireframeOverlayMode mode;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00B0FF) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mode.name,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF424242),
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: <InlineSpan>[
        TextSpan(
          text: '$label ',
          style: const TextStyle(color: Color(0xFF757575)),
        ),
        TextSpan(
          text: value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
    style: const TextStyle(fontSize: 11),
  );
}
