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

// go_router navigation-lab entrypoint.
//
// Run with:
//   flutter run -t lib/main_go_router.dart \
//     --dart-define=REALM=... --dart-define=RUM_ACCESS_TOKEN=...

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_example/navigation_lab/lab_views.dart';
import 'package:splunk_otel_flutter_example/navigation_lab/rum_setup.dart';

Future<void> main() async {
  await installSplunkRum(appName: 'Nav Lab - go_router');

  runApp(_GoRouterApp());
}

class _GoRouterApp extends StatelessWidget {
  _GoRouterApp();

  // go_router forwards observers to the navigator it manages. No SDK
  // dependency on go_router is required - the app supplies the observer.
  // A viewNamePredicate maps the go_router state name/path to a clean
  // screen name.
  final GoRouter _router = GoRouter(
    observers: [
      SplunkNavigatorObserver(
        viewNamePredicate: (route, defaultName) =>
            defaultName.isEmpty ? null : defaultName,
      ),
    ],
    routes: [
      GoRoute(
        path: '/',
        name: 'Home',
        builder: (context, state) => HomeView(
          flavor: 'go_router',
          onOpenDetails: (id) => context.push('/details/$id'),
          onOpenSettings: () => context.push('/settings'),
          onOpenTabs: () => context.push('/tabs'),
        ),
      ),
      GoRoute(
        path: '/details/:id',
        name: 'Details',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';

          return DetailsView(
            id: id,
            onOpenDetails: (next) => context.push('/details/$next'),
            onBack: () => context.pop(),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'Settings',
        builder: (context, state) => SettingsView(onBack: () => context.pop()),
      ),
      GoRoute(
        path: '/tabs',
        name: 'Tabs',
        builder: (context, state) => TabsView(onBack: () => context.pop()),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'go_router', routerConfig: _router);
  }
}
