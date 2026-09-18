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
import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
// ignore: implementation_imports
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

const _channelName =
    'dev.flutter.pigeon.splunk_otel_flutter_platform_interface'
    '.SplunkOtelFlutterHostApi.customTrackingTrackError';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const channel = BasicMessageChannel<Object?>(
    _channelName,
    SplunkOtelFlutterHostApi.pigeonChannelCodec,
  );

  group('CustomTracking.trackError', () {
    GeneratedError? received;

    void setSuccessHandler() {
      binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        channel,
        (message) async {
          received = (message! as List<Object?>)[0] as GeneratedError;

          return <Object?>[null];
        },
      );
    }

    setUp(() {
      received = null;
    });

    tearDown(() {
      binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        channel,
        null,
      );
    });

    test('derives type and message from an Error object', () async {
      setSuccessHandler();

      await SplunkRum.instance.customTracking.trackError(
        const FormatException('bad input'),
      );

      expect(received?.type, 'FormatException');
      expect(received?.message, 'FormatException: bad input');
    });

    test('uses String type for string errors', () async {
      setSuccessHandler();

      await SplunkRum.instance.customTracking.trackError('something failed');

      expect(received?.type, 'String');
      expect(received?.message, 'something failed');
    });

    test('preserves an explicitly supplied stacktrace verbatim', () async {
      setSuccessHandler();

      await SplunkRum.instance.customTracking.trackError(
        'boom',
        stackTrace: StackTrace.fromString('frame-a\nframe-b'),
      );

      expect(received?.stacktrace, 'frame-a\nframe-b');
    });

    test('falls back to a current stacktrace when none is passed', () async {
      setSuccessHandler();

      await SplunkRum.instance.customTracking.trackError('boom');

      expect(received?.stacktrace, isNotNull);
      expect(received?.stacktrace, isNotEmpty);
    });

    test('maps source, handled and attributes', () async {
      setSuccessHandler();

      await SplunkRum.instance.customTracking.trackError(
        'boom',
        source: ErrorSource.custom,
        handled: false,
        attributes: MutableAttributes(
          attributes: {'screen.name': MutableAttributeString(value: 'Cart')},
        ),
      );

      expect(received?.source, 'custom');
      expect(received?.handled, false);
      expect(received?.attributes?.attributes.length, 1);
    });

    test(
      'completes without throwing when the bridge reports an error',
      () async {
        binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
          channel,
          (message) async => <Object?>['ERROR', 'bridge failure', null],
        );

        await expectLater(
          SplunkRum.instance.customTracking.trackError('boom'),
          completes,
        );
      },
    );

    test('completes without throwing when no handler is registered', () async {
      binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        channel,
        null,
      );

      await expectLater(
        SplunkRum.instance.customTracking.trackError('boom'),
        completes,
      );
    });
  });
}
