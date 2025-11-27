// lib/test_harness.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum TestCategory { crashes,navigation, customTracking, performance, network }
enum MobilePlatform { android, ios }

extension on Set<MobilePlatform> {
  bool get isAndroidOnly => length == 1 && contains(MobilePlatform.android);
  bool get isIosOnly => length == 1 && contains(MobilePlatform.ios);
  bool get isBoth => containsAll({MobilePlatform.android, MobilePlatform.ios});

  String get label {
    if (isBoth) return 'Android • iOS';
    if (isAndroidOnly) return 'Android';
    if (isIosOnly) return 'iOS';
    return map((p) => p.name).join(', ');
  }
}

class TestAction {
  final String title;
  final String description;
  final TestCategory category;
  final Set<MobilePlatform> platforms;
  final Future<void> Function() onTap;

  const TestAction({
    required this.title,
    required this.category,
    required this.platforms,
    required this.onTap,
    required this.description,
  });
}

/// Displays tests grouped by category with platform color-coded buttons and badges.
class TestActionsWidget extends StatefulWidget {
  final List<TestAction> actions;

  const TestActionsWidget({super.key, required this.actions});

  @override
  State<TestActionsWidget> createState() => _TestActionsWidgetState();
}

class _TestActionsWidgetState extends State<TestActionsWidget> {
  late final Stream<DateTime> _clock =
  Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now())
      .asBroadcastStream();

  String _platformText = '—';
  String _deviceText = '—';
  String _systemText = '—';

  /// Stores last press timestamp per action title (assumes unique titles).
  final Map<String, DateTime> _lastPressedByTitle = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceMeta();
  }

  Future<void> _loadDeviceMeta() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        final manufacturer = info.manufacturer.trim();
        final model = info.model.trim();
        final sdk = info.version.sdkInt.toString();
        final release = info.version.release.trim();

        _platformText = 'Android';
        _deviceText = [manufacturer, model].where((e) => e.isNotEmpty).join(' ');
        _systemText = 'API $sdk / $release';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        final model = info.utsname.machine.trim();
        final version = info.systemVersion;

        _platformText = 'iOS';
        _deviceText = model;
        _systemText = 'iOS $version';
      } else {
        _platformText = Platform.operatingSystem;
        _deviceText = 'Unknown Device';
        _systemText = Platform.operatingSystemVersion;
      }
    } catch (_) {
      _platformText = 'Unknown';
      _deviceText = '—';
      _systemText = '—';
    }
    if (mounted) setState(() {});
  }

  Map<TestCategory, List<TestAction>> _groupByCategory(List<TestAction> list) {
    final map = <TestCategory, List<TestAction>>{};
    for (final a in list) {
      map.putIfAbsent(a.category, () => []).add(a);
    }
    return map;
  }

  /// Formats HH:mm:ss (local) without bringing in intl.
  String _hms(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory(widget.actions);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              StreamBuilder<DateTime>(
                stream: _clock,
                builder: (_, snap) {
                  final dt = snap.data ?? DateTime.now();
                  return Text(
                    _hms(dt),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_platformText • $_deviceText • $_systemText',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: widget.actions.isEmpty
              ? const _EmptyState()
              : ListView(
            padding: const EdgeInsets.all(10),
            children: TestCategory.values
                .where((c) => (grouped[c] ?? const []).isNotEmpty)
                .expand((category) sync* {
              yield Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                child: Text(
                  _labelForCategory(category),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
              for (final a in grouped[category]!) {
                yield _ActionCard(
                  action: a,
                  lastPressed:
                  _lastPressedByTitle[a.title], // may be null
                  onPressed: () async {
                    // update timestamp immediately; then run the action
                    setState(() {
                      _lastPressedByTitle[a.title] = DateTime.now();
                    });
                    await a.onTap();
                  },
                  formatHms: _hms,
                );
                yield const SizedBox(height: 8);
              }
            })
                .toList(),
          ),
        ),
      ],
    );
  }

  static String _labelForCategory(TestCategory c) => switch (c) {
    TestCategory.crashes => 'Crashes',
    TestCategory.navigation => 'Navigation',
    TestCategory.customTracking => 'Custom Tracking',
    TestCategory.performance => 'Performance',
    TestCategory.network => 'Network',
  };
}

class _ActionCard extends StatelessWidget {
  final TestAction action;
  final DateTime? lastPressed;
  final Future<void> Function() onPressed;
  final String Function(DateTime) formatHms;

  const _ActionCard({
    required this.action,
    required this.lastPressed,
    required this.onPressed,
    required this.formatHms,
  });

  Color _platformColor(Set<MobilePlatform> p) {
    if (p.isAndroidOnly) return Colors.green.shade600;
    if (p.isIosOnly) return Colors.grey.shade800;
    return Colors.deepPurple.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: scheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + platform badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _PlatformBadges(platforms: action.platforms),
              ],
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: 0.8,
              child: Text(
                'Runs on: ${action.platforms.label} • ${_labelForCategory(action.category)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 6),

            // Description • Last pressed • Test button (single row, compact)
            Row(
              children: [
                // Description expands
                Expanded(
                  child: Text(
                    action.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),

                // Subtle last-pressed timestamp (doesn't increase height)
                if (lastPressed != null)
                  Opacity(
                    opacity: 0.7,
                    child: Text(
                      'Last: ${formatHms(lastPressed!.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                if (lastPressed == null)
                  Opacity(
                    opacity: 0.5,
                    child: Text(
                      'Last: —',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),

                const SizedBox(width: 8),

                // Test button
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _platformColor(action.platforms),
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    minimumSize: const Size(0, 34),
                  ),
                  onPressed: onPressed,
                  child: const Text('Test'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _labelForCategory(TestCategory c) => switch (c) {
    TestCategory.crashes => 'Crashes',
    TestCategory.navigation => 'Navigation',
    TestCategory.customTracking => 'Custom Tracking',
    TestCategory.performance => 'Performance',
    TestCategory.network => 'Network',
  };
}

class _PlatformBadges extends StatelessWidget {
  final Set<MobilePlatform> platforms;

  const _PlatformBadges({required this.platforms});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;

    final children = <Widget>[
      if (platforms.contains(MobilePlatform.android))
        _Badge(
          icon: Icons.android,
          label: 'Android',
          bg: bg,
          color: Colors.green.shade600,
        ),
      if (platforms.contains(MobilePlatform.ios))
        _Badge(
          icon: Icons.apple,
          label: 'iOS',
          bg: bg,
          color: Colors.grey.shade800,
        ),
    ];

    if (children.isEmpty) {
      children.addAll([
        _Badge(
          icon: Icons.android,
          label: 'Android',
          bg: bg,
          color: Colors.green.shade600,
        ),
        _Badge(
          icon: Icons.apple,
          label: 'iOS',
          bg: bg,
          color: Colors.grey.shade800,
        ),
      ]);
    }

    return Wrap(spacing: 6, children: children);
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Opacity(
        opacity: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_remove, size: 38),
            SizedBox(height: 10),
            Text('No tests added yet'),
          ],
        ),
      ),
    );
  }
}
