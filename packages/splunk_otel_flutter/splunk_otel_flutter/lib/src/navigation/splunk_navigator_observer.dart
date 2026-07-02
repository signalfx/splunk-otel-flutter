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

  String? _lastScreenName;
  bool _initialRouteSeen = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    if (!_initialRouteSeen) {
      _initialRouteSeen = true;
      if (!trackInitialRoute) {
        // Record the name so a later return to it can still be deduplicated,
        // but do not emit for the initial route.
        _lastScreenName = _resolveName(route) ?? _lastScreenName;

        return;
      }
    }

    _handle(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    _initialRouteSeen = true;

    _handle(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    // Popping reveals the route underneath, which becomes the active screen.
    _handle(previousRoute);
  }

  void _handle(Route<dynamic>? route) {
    // Navigation callbacks must never throw or surface unhandled async errors.
    // Any failure here - including user-supplied predicate callbacks and the
    // bridged track call - is swallowed and only logged when the SDK has debug
    // logging enabled.
    try {
      if (route == null) {
        return;
      }

      if (!trackPopupRoutes && route is PopupRoute) {
        return;
      }

      if (shouldTrackView != null && !shouldTrackView!(route)) {
        return;
      }

      final name = _resolveName(route);
      if (name == null) {
        return;
      }

      if (name == _lastScreenName) {
        return;
      }
      _lastScreenName = name;

      final attributes = attributesFromRoute?.call(route);

      unawaited(_track(name, attributes));
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
