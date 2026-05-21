import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:splunk_otel_flutter_root_example_app/main.dart' as app;

const int telemetrySettleSeconds = int.fromEnvironment(
  'TELEMETRY_SETTLE_SECONDS',
  defaultValue: 90,
);
const int appErrorCount = int.fromEnvironment(
  'APP_ERROR_COUNT',
  defaultValue: 3,
);

const MethodChannel _diagnosticsChannel = MethodChannel(
  'splunk_otel_flutter_root_example_app/crash',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('handled app errors are reported', (tester) async {
    app.main();

    await pumpUntilVisible(tester, find.text('SmartCinema'));

    final reportedCount = await _diagnosticsChannel.invokeMethod<int>(
      'appErrors',
      <String, int>{'count': appErrorCount},
    );

    debugPrint('Reported app errors: $reportedCount');
    expect(reportedCount, appErrorCount);

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
