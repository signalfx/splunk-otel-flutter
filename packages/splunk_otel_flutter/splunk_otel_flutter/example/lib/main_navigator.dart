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

// Navigator 1.0 (imperative) navigation-lab entrypoint.
//
// Run with:
//   flutter run -t lib/main_navigator.dart \
//     --dart-define=REALM=... --dart-define=RUM_ACCESS_TOKEN=...

import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_example/navigation_lab/lab_views.dart';
import 'package:splunk_otel_flutter_example/navigation_lab/rum_setup.dart';

// Why this lab's screen names differ from the go_router / auto_route labs:
//
// The observer reports whatever the app puts in `RouteSettings.name`. Raw
// Navigator 1.0 has no single naming convention, so this lab uses named routes
// that encode the route argument (e.g. 'Details/42'). Each instance therefore
// reports a distinct `screen.name`, which is why pushing/popping the Details
// stack shows 'Details/42', 'Details/43', ... individually.
//
// By contrast, go_router reports the static `GoRoute.name` ('Details') and
// auto_route reports the generated route name ('DetailsRoute') - both are a
// single static name per screen. None of this is the observer behaving
// differently; it is purely how each routing approach names routes. Use
// `viewNamePredicate` to normalize names if a uniform shape is desired.
Future<void> main() async {
  await installSplunkRum(appName: 'Nav Lab - Navigator 1.0');

  runApp(const _NavigatorApp());
}

class _NavigatorApp extends StatelessWidget {
  const _NavigatorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigator 1.0',
      // The observer attaches to the root Navigator created by MaterialApp.
      navigatorObservers: [SplunkNavigatorObserver()],
      initialRoute: 'Home',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? 'Home';

    if (name.startsWith('Details/')) {
      final id = name.substring('Details/'.length);

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => DetailsView(
          id: id,
          onOpenDetails: (next) =>
              Navigator.of(context).pushNamed('Details/$next'),
          onBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    switch (name) {
      case 'Settings':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) =>
              SettingsView(onBack: () => Navigator.of(context).pop()),
        );
      case 'Tabs':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) =>
              TabsView(onBack: () => Navigator.of(context).pop()),
        );
      case 'Home':
      default:
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'Home'),
          builder: (context) => HomeView(
            flavor: 'Navigator 1.0',
            onOpenDetails: (id) =>
                Navigator.of(context).pushNamed('Details/$id'),
            onOpenSettings: () => Navigator.of(context).pushNamed('Settings'),
            onOpenTabs: () => Navigator.of(context).pushNamed('Tabs'),
            onReplaceWithSettings: () =>
                Navigator.of(context).pushReplacementNamed('Settings'),
          ),
        );
    }
  }
}
