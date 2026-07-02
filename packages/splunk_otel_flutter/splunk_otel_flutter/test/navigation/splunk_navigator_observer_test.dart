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

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

const _navigationTrackChannel =
    'dev.flutter.pigeon.splunk_otel_flutter_platform_interface'
    '.SplunkOtelFlutterHostApi.navigationTrack';

/// Captures the navigation track calls bridged to the (mocked) native side.
class _TrackSpy {
  final List<String> names = [];
  final List<GeneratedMutableAttributes?> attributes = [];

  void install() {
    const channel = BasicMessageChannel<Object?>(
      _navigationTrackChannel,
      SplunkOtelFlutterHostApi.pigeonChannelCodec,
    );

    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(channel, (
          Object? message,
        ) async {
          final args = message! as List<Object?>;
          names.add(args[0]! as String);
          attributes.add(args[1] as GeneratedMutableAttributes?);

          return <Object?>[];
        });
  }

  void uninstall() {
    const channel = BasicMessageChannel<Object?>(
      _navigationTrackChannel,
      SplunkOtelFlutterHostApi.pigeonChannelCodec,
    );

    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(channel, null);
  }
}

Route<void> _page(String? name) => PageRouteBuilder<void>(
  settings: RouteSettings(name: name),
  pageBuilder: (_, _, _) => const SizedBox.shrink(),
);

class _FakePopupRoute extends PopupRoute<void> {
  _FakePopupRoute({String? name}) : super(settings: RouteSettings(name: name));

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => const SizedBox.shrink();
}

/// Lets the unawaited bridge call settle.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TrackSpy spy;

  setUp(() {
    spy = _TrackSpy()..install();
  });

  tearDown(() {
    spy.uninstall();
  });

  group('SplunkNavigatorObserver', () {
    test('tracks the pushed route name', () async {
      SplunkNavigatorObserver().didPush(_page('Home'), null);
      await _settle();

      expect(spy.names, ['Home']);
    });

    test('deduplicates consecutive pushes of the same name', () async {
      final observer = SplunkNavigatorObserver();
      observer.didPush(_page('Home'), null);
      observer.didPush(_page('Home'), _page('Home'));
      await _settle();

      expect(spy.names, ['Home']);
    });

    test('tracks the new route on replace', () async {
      SplunkNavigatorObserver().didReplace(
        newRoute: _page('Details'),
        oldRoute: _page('Home'),
      );
      await _settle();

      expect(spy.names, ['Details']);
    });

    test('tracks the revealed route on pop', () async {
      SplunkNavigatorObserver().didPop(_page('Details'), _page('Home'));
      await _settle();

      expect(spy.names, ['Home']);
    });

    test('skips the initial route when trackInitialRoute is false', () async {
      final observer = SplunkNavigatorObserver(trackInitialRoute: false);
      observer.didPush(_page('Home'), null);
      observer.didPush(_page('Details'), _page('Home'));
      await _settle();

      expect(spy.names, ['Details']);
    });

    test('ignores popup routes by default', () async {
      SplunkNavigatorObserver().didPush(_FakePopupRoute(name: 'Dialog'), null);
      await _settle();

      expect(spy.names, isEmpty);
    });

    test('tracks named popup routes when trackPopupRoutes is true', () async {
      SplunkNavigatorObserver(
        trackPopupRoutes: true,
      ).didPush(_FakePopupRoute(name: 'Dialog'), null);
      await _settle();

      expect(spy.names, ['Dialog']);
    });

    test(
      'skips unnamed popup routes even when trackPopupRoutes is true',
      () async {
        SplunkNavigatorObserver(
          trackPopupRoutes: true,
        ).didPush(_FakePopupRoute(), null);
        await _settle();

        expect(spy.names, isEmpty);
      },
    );

    test('skips unnamed routes without a predicate', () async {
      SplunkNavigatorObserver().didPush(_page(null), null);
      await _settle();

      expect(spy.names, isEmpty);
    });

    test('viewNamePredicate renames the screen', () async {
      SplunkNavigatorObserver(
        viewNamePredicate: (route, defaultName) => 'Renamed',
      ).didPush(_page('Home'), null);
      await _settle();

      expect(spy.names, ['Renamed']);
    });

    test('viewNamePredicate can resolve an unnamed route', () async {
      SplunkNavigatorObserver(
        viewNamePredicate: (route, defaultName) =>
            defaultName.isEmpty ? 'Fallback' : defaultName,
      ).didPush(_page(null), null);
      await _settle();

      expect(spy.names, ['Fallback']);
    });

    test('viewNamePredicate returning null suppresses tracking', () async {
      SplunkNavigatorObserver(
        viewNamePredicate: (route, defaultName) => null,
      ).didPush(_page('Home'), null);
      await _settle();

      expect(spy.names, isEmpty);
    });

    test('shouldTrackView false suppresses tracking', () async {
      SplunkNavigatorObserver(
        shouldTrackView: (route) => false,
      ).didPush(_page('Secret'), null);
      await _settle();

      expect(spy.names, isEmpty);
    });

    test('forwards null attributes when none are provided', () async {
      SplunkNavigatorObserver().didPush(_page('Home'), null);
      await _settle();

      expect(spy.attributes.single, isNull);
    });

    test('forwards custom attributes from attributesFromRoute', () async {
      SplunkNavigatorObserver(
        attributesFromRoute: (route) => MutableAttributes(
          attributes: {'section': MutableAttributeString(value: 'shoes')},
        ),
      ).didPush(_page('Catalog'), null);
      await _settle();

      expect(spy.attributes.single!.attributes.containsKey('section'), isTrue);
    });

    test('never throws when a predicate throws', () async {
      final observer = SplunkNavigatorObserver(
        viewNamePredicate: (route, defaultName) =>
            throw StateError('predicate boom'),
      );

      expect(() => observer.didPush(_page('Home'), null), returnsNormally);
      await _settle();

      expect(spy.names, isEmpty);
    });

    test('strips reserved keys before bridging', () async {
      SplunkNavigatorObserver(
        attributesFromRoute: (route) => MutableAttributes(
          attributes: {
            'screen.name': MutableAttributeString(value: 'spoofed'),
            'component': MutableAttributeString(value: 'spoofed'),
            'custom': MutableAttributeString(value: 'ok'),
          },
        ),
      ).didPush(_page('Catalog'), null);
      await _settle();

      final forwarded = spy.attributes.single!.attributes;
      expect(forwarded.containsKey('custom'), isTrue);
      expect(forwarded.containsKey('screen.name'), isFalse);
      expect(forwarded.containsKey('component'), isFalse);
    });
  });
}
