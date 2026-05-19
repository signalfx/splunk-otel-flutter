import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:splunk_otel_flutter_root_example_app/main.dart' as app;

const int telemetrySettleSeconds = int.fromEnvironment(
  'TELEMETRY_SETTLE_SECONDS',
  defaultValue: 90,
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native network requests and errors are reported', (
    tester,
  ) async {
    app.main();

    await pumpUntilVisible(tester, find.text('SmartCinema'));

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

    await Future<void>.delayed(const Duration(seconds: telemetrySettleSeconds));

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
