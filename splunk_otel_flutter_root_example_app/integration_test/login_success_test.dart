import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:splunk_otel_flutter_root_example_app/main.dart' as app;
import 'package:splunk_otel_flutter_root_example_app/screen/login_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/welcome_screen.dart';

const int telemetrySettleSeconds = int.fromEnvironment(
  'TELEMETRY_SETTLE_SECONDS',
  defaultValue: 30,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('successful login opens the home screen', (tester) async {
    app.main();

    await pumpUntilVisible(tester, find.text('SmartCinema'));

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

    await Future<void>.delayed(const Duration(seconds: telemetrySettleSeconds));
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
