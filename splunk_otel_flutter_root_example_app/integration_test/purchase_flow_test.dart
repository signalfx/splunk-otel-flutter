/*
 * Copyright 2025 Splunk Inc.
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
import 'package:integration_test/integration_test.dart';
import 'package:splunk_otel_flutter_root_example_app/main.dart' as app;
import 'package:splunk_otel_flutter_root_example_app/screen/login_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/welcome_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    binding.reportData = <String, dynamic>{'completed': true};
  });

  testWidgets('valid login can purchase Spiderman movie download', (
    tester,
  ) async {
    app.main();

    await pumpUntilVisible(tester, find.text('SmartCinema'));

    await tapAndWait(tester, find.byKey(welcomeGetStartedButtonKey));
    await pumpUntilVisible(tester, find.text('Login'));

    await tester.enterText(find.byKey(loginEmailFieldKey), 'jan@smartlook.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'test-password');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tapAndWait(tester, find.byKey(loginButtonKey));

    await pumpUntilVisible(tester, find.text('Spiderman: No Way Home'));
    await tapAndWait(tester, find.text('Spiderman: No Way Home').first);

    await pumpUntilVisible(tester, find.byIcon(Icons.download));
    await tapAndWait(tester, find.byIcon(Icons.download));

    await pumpUntilVisible(tester, find.text('Premium Account'));
    await tapAndWait(tester, find.widgetWithText(TextButton, 'PURCHASE'));

    await pumpUntilVisible(
      tester,
      find.widgetWithText(ElevatedButton, 'CONTINUE'),
    );
    await tapAndWait(tester, find.widgetWithText(ElevatedButton, 'CONTINUE'));

    await pumpUntilVisible(
      tester,
      find.widgetWithText(ElevatedButton, 'PURCHASE'),
    );
    await tapAndWait(tester, find.widgetWithText(ElevatedButton, 'PURCHASE'));

    await pumpUntilVisible(
      tester,
      find.text('Payment successfully\ncompleted'),
    );
    expect(find.text('Payment successfully\ncompleted'), findsOneWidget);

    await tapAndWait(tester, find.widgetWithText(TextButton, 'DONE'));
  });
}

Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 500));
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
