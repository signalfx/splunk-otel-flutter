import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:splunk_otel_flutter_root_example_app/main.dart' as app;
import 'package:splunk_otel_flutter_root_example_app/screen/login_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/welcome_screen.dart';

const int telemetrySettleSeconds = int.fromEnvironment(
  'TELEMETRY_SETTLE_SECONDS',
  defaultValue: 90,
);
const int loginSettleSeconds = int.fromEnvironment(
  'LOGIN_SETTLE_SECONDS',
  defaultValue: 10,
);
const int networkSettleSeconds = int.fromEnvironment(
  'NETWORK_TELEMETRY_SETTLE_SECONDS',
  defaultValue: telemetrySettleSeconds,
);
const int appErrorCount = int.fromEnvironment(
  'APP_ERROR_COUNT',
  defaultValue: 3,
);
const int appErrorSettleSeconds = int.fromEnvironment(
  'APP_ERROR_TELEMETRY_SETTLE_SECONDS',
  defaultValue: telemetrySettleSeconds,
);
const int anrBlockSeconds = int.fromEnvironment(
  'ANR_BLOCK_SECONDS',
  defaultValue: 15,
);
const int anrSettleSeconds = int.fromEnvironment(
  'ANR_TELEMETRY_SETTLE_SECONDS',
  defaultValue: telemetrySettleSeconds,
);

const String networkSuccessUrl = String.fromEnvironment(
  'NETWORK_SUCCESS_URL',
  defaultValue: 'https://example.com/',
);
const String networkHttpErrorUrl = String.fromEnvironment(
  'NETWORK_HTTP_ERROR_URL',
  defaultValue: 'https://httpbin.org/status/500',
);
const String networkFailureUrl = String.fromEnvironment(
  'NETWORK_FAILURE_URL',
  defaultValue: 'https://127.0.0.1:65534/',
);

const MethodChannel _diagnosticsChannel = MethodChannel(
  'splunk_otel_flutter_root_example_app/crash',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    binding.reportData = <String, dynamic>{
      'completed': true,
      'suite': 'telemetry_suite',
    };
  });

  testWidgets(
    'login, network diagnostics, app errors, and ANR telemetry suite',
    (tester) async {
      app.main();

      await pumpUntilVisible(tester, find.text('SmartCinema'));

      await performSuccessfulLogin(tester);
      await waitForTelemetry('login success', loginSettleSeconds);

      await runNetworkDiagnostics();
      await waitForTelemetry('network diagnostics', networkSettleSeconds);
      await tester.pump();
      expect(find.text('Trending'), findsOneWidget);

      await runAppErrors();
      await waitForTelemetry('handled app errors', appErrorSettleSeconds);
      await tester.pump();
      expect(find.text('Trending'), findsOneWidget);

      await triggerNativeAnr();
      await waitForTelemetry('ANR', anrBlockSeconds + anrSettleSeconds);
      await tester.pump();
      expect(find.text('Trending'), findsOneWidget);
    },
  );
}

Future<void> performSuccessfulLogin(WidgetTester tester) async {
  await tester.tap(find.byKey(welcomeGetStartedButtonKey));
  await pumpUntilVisible(tester, find.text('Login'));

  await tester.enterText(find.byKey(loginEmailFieldKey), 'jan@smartlook.com');
  await tester.enterText(find.byKey(loginPasswordFieldKey), 'test-password');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.tap(find.byKey(loginButtonKey));
  await pumpUntilVisible(tester, find.text('Trending'));

  expect(find.text('Trending'), findsOneWidget);
  expect(find.text('New'), findsOneWidget);
  expect(find.text('Home'), findsOneWidget);
  expect(find.text('Favorites'), findsOneWidget);
}

Future<void> runNetworkDiagnostics() async {
  final results = await _diagnosticsChannel.invokeMethod<List<dynamic>>(
    'networkRequests',
    <String, List<String>>{
      'urls': <String>[
        networkSuccessUrl,
        networkHttpErrorUrl,
        networkFailureUrl,
      ],
    },
  );

  debugPrint('Network diagnostics results: $results');
  expect(results, isNotNull);
  expect(results, hasLength(3));
}

Future<void> runAppErrors() async {
  final reportedCount = await _diagnosticsChannel.invokeMethod<int>(
    'appErrors',
    <String, int>{'count': appErrorCount},
  );

  debugPrint('Reported app errors: $reportedCount');
  expect(reportedCount, appErrorCount);
}

Future<void> triggerNativeAnr() async {
  unawaited(
    _diagnosticsChannel.invokeMethod<void>('anr', <String, int>{
      'blockMillis': anrBlockSeconds * 1000,
    }),
  );
}

Future<void> waitForTelemetry(String stepName, int seconds) async {
  debugPrint('Waiting $seconds seconds for $stepName telemetry.');
  await Future<void>.delayed(Duration(seconds: seconds));
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
