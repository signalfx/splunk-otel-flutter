import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:splunk_otel_flutter_root_example_app/main.dart' as app;

const int anrBlockSeconds = int.fromEnvironment(
  'ANR_BLOCK_SECONDS',
  defaultValue: 15,
);
const int telemetrySettleSeconds = int.fromEnvironment(
  'TELEMETRY_SETTLE_SECONDS',
  defaultValue: 60,
);

const MethodChannel _diagnosticsChannel = MethodChannel(
  'splunk_otel_flutter_root_example_app/crash',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native Android ANR is generated', (tester) async {
    app.main();

    await pumpUntilVisible(tester, find.text('SmartCinema'));

    unawaited(
      _diagnosticsChannel.invokeMethod<void>('anr', <String, int>{
        'blockMillis': anrBlockSeconds * 1000,
      }),
    );

    await Future<void>.delayed(
      const Duration(seconds: anrBlockSeconds + telemetrySettleSeconds),
    );

    await tester.pump();
    expect(find.text('SmartCinema'), findsOneWidget);
  });
}

Future<void> pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));

    if (tester.any(finder)) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  expect(finder, findsOneWidget);
}
