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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/privacy/sensitive_area.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/privacy/sensitivity_resolver.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

const Color _red = Color(0xFFFF0000);
const Color _blue = Color(0xFF0000FF);

List<WireframeNode> _flatten(WireframeNode node) => <WireframeNode>[
  node,
  for (final child in node.children) ..._flatten(child),
];

List<WireframeSkeleton> _skeletons(WireframeNode root) => <WireframeSkeleton>[
  for (final node in _flatten(root)) ...node.skeletons,
];

List<WireframeNode> _sensitiveNodes(WireframeNode root) =>
    _flatten(root).where((node) => node.isSensitive).toList();

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(alignment: Alignment.topLeft, child: child),
);

void main() {
  late WireframeWalker walker;

  setUp(() {
    walker = WireframeWalker();
  });

  group('SensitiveArea', () {
    testWidgets('should withhold all paint from a masked subtree', (
      tester,
    ) async {
      const content = ColoredBox(
        color: _red,
        child: SizedBox(
          width: 60,
          height: 40,
          child: Text(
            'account balance',
            style: TextStyle(color: _blue, fontSize: 12),
          ),
        ),
      );

      // Captured unmasked first, so the masked expectation below cannot pass
      // just because this tree happens to paint nothing.
      await tester.pumpWidget(_host(content));

      expect(_skeletons(walker.capture().single.root), isNotEmpty);

      await tester.pumpWidget(_host(const SensitiveArea(child: content)));

      final root = walker.capture().single.root;

      expect(_skeletons(root), isEmpty);
      expect(_sensitiveNodes(root), isNotEmpty);
    });

    testWidgets('should still report the geometry of masked content', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SensitiveArea(
            child: ColoredBox(
              color: _red,
              child: SizedBox(width: 60, height: 40),
            ),
          ),
        ),
      );

      final node = _flatten(
        walker.capture().single.root,
      ).firstWhere((node) => node.type == 'ColoredBox');

      expect(node.rect, const Rect.fromLTWH(0, 0, 60, 40));
      expect(node.isSensitive, isTrue);
      expect(node.skeletons, isEmpty);
      expect(node.toJson()['isSensitive'], isTrue);
    });

    testWidgets('should leave content outside the marked subtree alone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: <Widget>[
              SensitiveArea(
                child: ColoredBox(
                  color: _red,
                  child: SizedBox(width: 60, height: 40),
                ),
              ),
              ColoredBox(color: _blue, child: SizedBox(width: 60, height: 40)),
            ],
          ),
        ),
      );

      final skeletons = _skeletons(walker.capture().single.root);

      expect(skeletons.map((skeleton) => skeleton.color), <Color>[_blue]);
    });

    testWidgets('should mask a subtree nested below the marker', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SensitiveArea(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                child: ColoredBox(
                  color: _red,
                  child: SizedBox(width: 20, height: 20),
                ),
              ),
            ),
          ),
        ),
      );

      expect(_skeletons(walker.capture().single.root), isEmpty);
    });

    testWidgets('should reveal a subtree that opts back out', (tester) async {
      await tester.pumpWidget(
        _host(
          const SensitiveArea(
            child: Column(
              children: <Widget>[
                ColoredBox(color: _red, child: SizedBox(width: 60, height: 40)),
                SensitiveArea(
                  isSensitive: false,
                  child: ColoredBox(
                    color: _blue,
                    child: SizedBox(width: 60, height: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final skeletons = _skeletons(walker.capture().single.root);

      expect(skeletons.map((skeleton) => skeleton.color), <Color>[_blue]);
    });

    testWidgets('should keep opacity on masked nodes', (tester) async {
      // Opacity describes compositing rather than content, so withholding it
      // would misplace the mask without protecting anything.
      await tester.pumpWidget(
        _host(
          const SensitiveArea(
            child: Opacity(
              opacity: 0.5,
              child: ColoredBox(
                color: _red,
                child: SizedBox(width: 20, height: 20),
              ),
            ),
          ),
        ),
      );

      final node = _flatten(
        walker.capture().single.root,
      ).firstWhere((node) => node.type == 'Opacity');

      expect(node.opacity, 0.5);
      expect(node.isSensitive, isTrue);
    });
  });

  group('text input', () {
    testWidgets('should mask editable text without being marked', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: TextEditingController(text: 'hunter2'),
              style: const TextStyle(color: _red, fontSize: 14),
            ),
          ),
        ),
      );

      final root = walker.capture().single.root;
      final editable = _flatten(
        root,
      ).where((node) => node.isSensitive).toList();

      expect(editable, isNotEmpty);
      // Nothing painted by the editable itself reaches the capture.
      for (final node in editable) {
        expect(node.skeletons, isEmpty);
      }
    });

    testWidgets('should not mask static text', (tester) async {
      await tester.pumpWidget(
        _host(
          const Text('public', style: TextStyle(color: _red, fontSize: 14)),
        ),
      );

      final root = walker.capture().single.root;

      expect(_sensitiveNodes(root), isEmpty);
      expect(_skeletons(root), isNotEmpty);
    });

    testWidgets('should leave editable text visible when the default is '
        'disabled', (tester) async {
      final permissive = WireframeWalker(
        sensitivityResolver: const SensitivityResolver(maskTextInput: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: TextEditingController(text: 'hunter2'),
              style: const TextStyle(color: _red, fontSize: 14),
            ),
          ),
        ),
      );

      expect(_sensitiveNodes(permissive.capture().single.root), isEmpty);
    });

    testWidgets('should still mask editable text inside a marked subtree when '
        'the default is disabled', (tester) async {
      final permissive = WireframeWalker(
        sensitivityResolver: const SensitivityResolver(maskTextInput: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SensitiveArea(
              child: TextField(
                controller: TextEditingController(text: 'hunter2'),
                style: const TextStyle(color: _red, fontSize: 14),
              ),
            ),
          ),
        ),
      );

      expect(_sensitiveNodes(permissive.capture().single.root), isNotEmpty);
    });
  });
}
