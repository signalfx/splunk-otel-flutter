import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:splunk_otel_flutter_root_example_app/main.dart' as app;
import 'package:splunk_otel_flutter_root_example_app/screen/login_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/welcome_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('email without at symbol exits the app', (tester) async {
    app.main();

    await pumpUntilVisible(tester, find.text('SmartCinema'));

    await tester.tap(find.byKey(welcomeGetStartedButtonKey));
    await pumpUntilVisible(tester, find.text('Login'));

    await tester.enterText(find.byKey(loginEmailFieldKey), 'invalid-email');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'test-password');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    await tester.tap(find.byKey(loginButtonKey));
    await tester.pump(const Duration(milliseconds: 500));

    fail('Expected the app to exit after login with an email missing "@".');
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
