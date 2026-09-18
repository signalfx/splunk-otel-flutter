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

import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

/// Router-agnostic presentational screens for the navigation lab.
///
/// Navigation is delegated to callbacks so the same widgets can be driven by
/// Navigator 1.0, go_router, and auto_route. Each entrypoint wires the
/// callbacks to its router's API.

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.flavor,
    required this.onOpenDetails,
    required this.onOpenSettings,
    required this.onOpenTabs,
    required this.onReplaceWithSettings,
  });

  /// Label identifying which routing library drives this run.
  final String flavor;
  final void Function(String id) onOpenDetails;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenTabs;
  final VoidCallback onReplaceWithSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigation Lab - $flavor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tile(
            title: 'Open Details (push)',
            subtitle: 'Pushes Details/42 - expect screen.name change',
            onTap: () => onOpenDetails('42'),
          ),
          _Tile(
            title: 'Open Settings (push)',
            subtitle: 'Pushes Settings',
            onTap: onOpenSettings,
          ),
          _Tile(
            title: 'Replace with Settings (pushReplacement)',
            subtitle:
                'Replaces the current route - should still track Settings',
            onTap: onReplaceWithSettings,
          ),
          _Tile(
            title: 'Open Tabs (IndexedStack)',
            subtitle: 'Tab switches push no route - NOT tracked',
            onTap: onOpenTabs,
          ),
          _Tile(
            title: 'Show Dialog',
            subtitle: 'Popup route - ignored by default',
            onTap: () => showLabDialog(context),
          ),
          _Tile(
            title: 'Manual track()',
            subtitle: 'Calls navigation.track with attributes',
            onTap: () => SplunkRum.instance.navigation.track(
              screenName: 'ManualScreen',
              attributes: MutableAttributes(
                attributes: {'source': MutableAttributeString(value: 'button')},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailsView extends StatelessWidget {
  const DetailsView({
    super.key,
    required this.id,
    required this.onOpenDetails,
    required this.onBack,
  });

  final String id;
  final void Function(String id) onOpenDetails;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final nextId = (int.tryParse(id) ?? 0) + 1;

    return Scaffold(
      appBar: AppBar(title: Text('Details $id')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Details for item $id'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onOpenDetails('$nextId'),
              child: Text('Push Details $nextId'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onBack, child: const Text('Back (pop)')),
          ],
        ),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: OutlinedButton(
          onPressed: onBack,
          child: const Text('Back (pop)'),
        ),
      ),
    );
  }
}

/// Demonstrates that tab switching via [IndexedStack] does not push a route and
/// is therefore not tracked by the observer.
class TabsView extends StatefulWidget {
  const TabsView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TabsView> createState() => _TabsViewState();
}

class _TabsViewState extends State<TabsView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabs (not tracked)'),
        leading: BackButton(onPressed: widget.onBack),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          Center(child: Text('Tab A')),
          Center(child: Text('Tab B')),
          Center(child: Text('Tab C')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.looks_one), label: 'A'),
          BottomNavigationBarItem(icon: Icon(Icons.looks_two), label: 'B'),
          BottomNavigationBarItem(icon: Icon(Icons.looks_3), label: 'C'),
        ],
      ),
    );
  }
}

/// Shows a dialog (a [PopupRoute]); ignored by the observer unless
/// `trackPopupRoutes` is enabled (and even then, a name is required).
Future<void> showLabDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Lab Dialog'),
      content: const Text('Popup routes are ignored by default.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
