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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_example/navigation_lab/lab_views.dart';

part 'auto_route_app.gr.dart';

/// auto_route router. Generated route classes (HomeRoute, DetailsRoute, ...)
/// live in the generated part file.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: DetailsRoute.page),
    AutoRoute(page: SettingsRoute.page),
    AutoRoute(page: TabsRoute.page),
  ];
}

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeView(
      flavor: 'auto_route',
      onOpenDetails: (id) => context.router.push(DetailsRoute(id: id)),
      onOpenSettings: () => context.router.push(const SettingsRoute()),
      onOpenTabs: () => context.router.push(const TabsRoute()),
      onReplaceWithSettings: () =>
          context.router.replace(const SettingsRoute()),
    );
  }
}

@RoutePage()
class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return DetailsView(
      id: id,
      onOpenDetails: (next) => context.router.push(DetailsRoute(id: next)),
      onBack: () => context.router.maybePop(),
    );
  }
}

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsView(onBack: () => context.router.maybePop());
  }
}

@RoutePage()
class TabsPage extends StatelessWidget {
  const TabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabsView(onBack: () => context.router.maybePop());
  }
}
