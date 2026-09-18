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

// auto_route navigation-lab entrypoint.
//
// Generate routes first:
//   dart run build_runner build --delete-conflicting-outputs
// Then run with:
//   flutter run -t lib/main_auto_route.dart \
//     --dart-define=REALM=... --dart-define=RUM_ACCESS_TOKEN=...

import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_example/navigation_lab/auto_route_app.dart';
import 'package:splunk_otel_flutter_example/navigation_lab/rum_setup.dart';

Future<void> main() async {
  await installSplunkRum(appName: 'Nav Lab - auto_route');

  runApp(_AutoRouteApp());
}

class _AutoRouteApp extends StatelessWidget {
  _AutoRouteApp();

  final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'auto_route',
      // auto_route forwards these observers to the navigator it manages.
      // The builder must return fresh instances per router.
      routerConfig: _appRouter.config(
        navigatorObservers: () => [SplunkNavigatorObserver()],
      ),
    );
  }
}
