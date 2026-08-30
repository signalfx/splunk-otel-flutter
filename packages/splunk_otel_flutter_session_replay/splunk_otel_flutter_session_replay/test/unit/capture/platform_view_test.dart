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

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/privacy/sensitive_area.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

/// Stands in for a real embedded view, which cannot be created in a test.
///
/// Only the identifier matters to capture, so the rest is inert.
class _FakePlatformViewController extends PlatformViewController {
  _FakePlatformViewController(this.viewId);

  @override
  final int viewId;

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {}

  @override
  Future<void> clearFocus() async {}

  @override
  Future<void> dispose() async {}
}

/// The first node in the tree that reports a native view.
WireframeNode? _platformViewNode(WireframeNode node) {
  if (node.nativeViewId != null) {
    return node;
  }
  for (final child in node.children) {
    final found = _platformViewNode(child);
    if (found != null) {
      return found;
    }
  }

  return null;
}

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Align(alignment: Alignment.topLeft, child: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('platform views', () {
    testWidgets('should report the embedded view identifier', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 120,
            height: 80,
            child: PlatformViewSurface(
              controller: _FakePlatformViewController(7),
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              gestureRecognizers:
                  const <Factory<OneSequenceGestureRecognizer>>{},
            ),
          ),
        ),
      );

      final node = _platformViewNode(WireframeWalker().capture().single.root);

      expect(node, isNotNull);
      expect(node!.nativeViewId, 7);
      expect(node.rect, const Rect.fromLTWH(0, 0, 120, 80));
    });

    testWidgets('should describe no content of its own', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 120,
            height: 80,
            child: PlatformViewSurface(
              controller: _FakePlatformViewController(7),
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              gestureRecognizers:
                  const <Factory<OneSequenceGestureRecognizer>>{},
            ),
          ),
        ),
      );

      final node = _platformViewNode(WireframeWalker().capture().single.root);

      expect(node!.skeletons, isEmpty);
    });

    testWidgets('should still report the identifier when masked', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SensitiveArea(
            child: SizedBox(
              width: 120,
              height: 80,
              child: PlatformViewSurface(
                controller: _FakePlatformViewController(7),
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                gestureRecognizers:
                    const <Factory<OneSequenceGestureRecognizer>>{},
              ),
            ),
          ),
        ),
      );

      final node = _platformViewNode(WireframeWalker().capture().single.root);

      expect(node!.isSensitive, isTrue);
      expect(node.nativeViewId, 7);
    });

    testWidgets('should leave an ordinary node without an identifier', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const SizedBox(width: 10, height: 10)));

      expect(
        _platformViewNode(WireframeWalker().capture().single.root),
        isNull,
      );
    });
  });
}
