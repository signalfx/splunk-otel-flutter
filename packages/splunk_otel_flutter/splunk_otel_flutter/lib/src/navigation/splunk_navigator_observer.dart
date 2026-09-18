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

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:splunk_otel_flutter/src/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

/// Resolves the screen name reported for a [route].
///
/// Receives the [defaultName] (the route's `settings.name`, or an empty string
/// when the route is unnamed). Return a non-empty string to report a custom
/// name, or return `null`/empty to skip tracking this route.
typedef SplunkViewNamePredicate =
    String? Function(Route<dynamic> route, String defaultName);

/// Decides whether a [route] should be tracked at all.
///
/// Return `false` to suppress tracking for the given route.
typedef SplunkShouldTrackView = bool Function(Route<dynamic> route);

/// Extracts custom attributes for a [route].
///
/// Returning `null` attaches no custom attributes. SDK-reserved keys are
/// stripped before the navigation signal is emitted.
typedef SplunkAttributesFromRoute =
    MutableAttributes? Function(Route<dynamic> route);

/// A [NavigatorObserver] that automatically reports screen navigation to
/// Splunk RUM.
///
/// Install it on the `Navigator` you want to observe and the SDK will report a
/// navigation signal on each committed route change, forwarding to the same
/// native path as [Navigation.track].
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [SplunkNavigatorObserver()],
/// );
/// ```
///
/// It also works with routing packages that delegate to a Flutter `Navigator`
/// and expose an observer slot, without the SDK depending on those packages:
///
/// ```dart
/// // go_router
/// GoRouter(observers: [SplunkNavigatorObserver()], routes: [...]);
///
/// // auto_route
/// AutoRouterConfig(navigatorObservers: () => [SplunkNavigatorObserver()]);
/// ```
///
/// Scope and limitations:
/// - Observes only the single `Navigator` it is attached to. Nested navigators
///   (per-tab stacks, shell routes) require installing an observer on each.
/// - Tab switches that do not push a route (e.g. `IndexedStack` /
///   `BottomNavigationBar`) are not detected.
/// - Popup routes (dialogs, modal bottom sheets, menus) are ignored by default;
///   set [trackPopupRoutes] to `true` to include them. Even then, most popups
///   are unnamed and remain skipped unless [viewNamePredicate] supplies a name.
/// - Unnamed routes report an empty default name and are skipped unless
///   [viewNamePredicate] supplies one.
///
/// This "off by default" choice matches the common RUM/analytics convention of
/// treating dialogs as transient overlays rather than screens (and the Splunk
/// native Android agent, which ignores `DialogFragment`). Note the native
/// agents themselves differ: iOS native automatic tracking does report modal
/// presentations, whereas Android ignores dialogs.
class SplunkNavigatorObserver extends NavigatorObserver {
  /// Creates an observer.
  ///
  /// [viewNamePredicate] - Renames or suppresses the reported screen name.
  /// [shouldTrackView] - Filters whether a route is tracked.
  /// [attributesFromRoute] - Extracts custom attributes from a route.
  /// [trackInitialRoute] - Whether to report the first route. Defaults to true.
  /// [trackPopupRoutes] - Whether to report popup routes (dialogs, bottom
  /// sheets, menus). Defaults to false. When enabled, unnamed popups still
  /// require a [viewNamePredicate] to produce a name.
  SplunkNavigatorObserver({
    this.viewNamePredicate,
    this.shouldTrackView,
    this.attributesFromRoute,
    this.trackInitialRoute = true,
    this.trackPopupRoutes = false,
  });

  /// Renames or suppresses the reported screen name.
  final SplunkViewNamePredicate? viewNamePredicate;

  /// Filters whether a route is tracked.
  final SplunkShouldTrackView? shouldTrackView;

  /// Extracts custom attributes from a route.
  final SplunkAttributesFromRoute? attributesFromRoute;

  /// Whether to report the first route encountered.
  final bool trackInitialRoute;

  /// Whether to report popup routes (dialogs, modal bottom sheets, menus).
  final bool trackPopupRoutes;

  /// Tracked routes currently live in the observed navigator, in stack order.
  ///
  /// Only routes that resolve to a trackable screen name are recorded, so the
  /// top entry is always the screen that should be reported. Skipped routes
  /// (unnamed, popup, or [shouldTrackView]-filtered) are transparent: popping
  /// back past one reveals the nearest tracked screen below it, rather than
  /// leaving `screen.name` stuck on the route that was just removed.
  final List<_TrackedRoute> _trackedStack = <_TrackedRoute>[];

  /// The most recently emitted screen name. Deduplicates repeat reports of the
  /// same screen; advanced only when an emission is actually dispatched.
  String? _emittedName;

  bool _initialRouteSeen = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    _guard(() {
      final suppressInitial = !_initialRouteSeen && !trackInitialRoute;
      _initialRouteSeen = true;

      _pushIfTracked(route);

      if (suppressInitial) {
        // Adopt the initial screen as already-reported so a later return to it
        // is still deduplicated, but do not emit for the initial route.
        final top = _currentTracked;
        if (top != null) {
          _emittedName = top.name;
        }

        return;
      }

      _emitCurrent();
    });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    _guard(() {
      _initialRouteSeen = true;
      _replaceTracked(oldRoute: oldRoute, newRoute: newRoute);
      _emitCurrent();
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    // Popping removes the top route; the nearest tracked route still on the
    // stack becomes the active screen (skipped routes are transparent).
    _guard(() {
      _removeTracked(route);
      _emitCurrent();
    });
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);

    // Navigator.removeRoute / removeRouteBelow can target any route in the
    // stack. Dropping its tracked entry keeps the stack accurate; screen.name
    // changes only when the removed route was the current top.
    _guard(() {
      _removeTracked(route);
      _emitCurrent();
    });
  }

  _TrackedRoute? get _currentTracked =>
      _trackedStack.isEmpty ? null : _trackedStack.last;

  /// Records [route] as the new tracked top when it resolves to a screen name.
  void _pushIfTracked(Route<dynamic> route) {
    final name = _trackableName(route);
    if (name == null) {
      return;
    }

    _trackedStack.add(_TrackedRoute(route, name));
  }

  /// Reflects a `replace` in the tracked stack, preserving stack order so a
  /// replacement below the visible top does not disturb the current screen.
  void _replaceTracked({
    required Route<dynamic>? oldRoute,
    required Route<dynamic>? newRoute,
  }) {
    final index = oldRoute == null
        ? -1
        : _trackedStack.indexWhere((entry) => identical(entry.route, oldRoute));

    final name = newRoute == null ? null : _trackableName(newRoute);

    if (index >= 0) {
      if (name == null) {
        _trackedStack.removeAt(index);
      } else {
        _trackedStack[index] = _TrackedRoute(newRoute!, name);
      }

      return;
    }

    // The replaced route was not tracked. Only record the new route when it is
    // the one now on screen, mirroring how a fresh push is handled.
    if (name != null && (newRoute?.isCurrent ?? false)) {
      _trackedStack.add(_TrackedRoute(newRoute!, name));
    }
  }

  void _removeTracked(Route<dynamic>? route) {
    if (route == null) {
      return;
    }

    _trackedStack.removeWhere((entry) => identical(entry.route, route));
  }

  /// Emits a navigation signal when the current tracked screen differs from the
  /// last one reported.
  void _emitCurrent() {
    final top = _currentTracked;
    final name = top?.name;

    if (name == null || name == _emittedName) {
      return;
    }

    // Extract attributes before advancing _emittedName so a throwing
    // attributesFromRoute does not suppress a later navigation (the dedupe
    // marker only moves once we are about to emit).
    final attributes = attributesFromRoute?.call(top!.route);

    _emittedName = name;

    unawaited(_track(name, attributes));
  }

  /// Resolves the trackable screen name for [route], or `null` when it should
  /// be skipped (popup while disabled, filtered out, or no usable name).
  String? _trackableName(Route<dynamic> route) {
    if (!trackPopupRoutes && route is PopupRoute) {
      return null;
    }

    if (shouldTrackView != null && !shouldTrackView!(route)) {
      return null;
    }

    return _resolveName(route);
  }

  /// Runs [action], swallowing and logging any error so navigation handling
  /// never throws or surfaces an unhandled async error into the host app.
  ///
  /// This covers user-supplied predicate callbacks and the bridged track call;
  /// failures are only logged when the SDK has debug logging enabled.
  void _guard(void Function() action) {
    try {
      action();
    } catch (error) {
      _logError(error);
    }
  }

  /// Bridges the screen change to the native agent. Any failure is caught and
  /// logged so it never surfaces as an unhandled async error.
  Future<void> _track(String screenName, MutableAttributes? attributes) async {
    try {
      await SplunkRum.instance.navigation.track(
        screenName: screenName,
        attributes: attributes,
      );
    } catch (error) {
      _logError(error);
    }
  }

  /// Logs a navigation-tracking failure, but only when the SDK has debug
  /// logging enabled. Never rethrows - navigation handling must stay silent on
  /// failure so it cannot break the host app's navigation.
  void _logError(Object error) {
    unawaited(_logIfDebug(error));
  }

  Future<void> _logIfDebug(Object error) async {
    try {
      if (await SplunkRum.instance.state.getIsDebugLoggingEnabled()) {
        debugPrint('SplunkRum: navigation tracking skipped ($error).');
      }
    } catch (_) {
      // Intentionally ignored: never throw from navigation handling.
    }
  }

  /// Resolves the effective screen name, or `null` when the route should be
  /// skipped (no usable name).
  String? _resolveName(Route<dynamic> route) {
    final defaultName = route.settings.name ?? '';

    final resolved = viewNamePredicate != null
        ? viewNamePredicate!(route, defaultName)
        : defaultName;

    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }
}

/// A route currently tracked on the observer's screen stack, paired with the
/// screen name resolved for it.
class _TrackedRoute {
  _TrackedRoute(this.route, this.name);

  final Route<dynamic> route;
  final String name;
}
