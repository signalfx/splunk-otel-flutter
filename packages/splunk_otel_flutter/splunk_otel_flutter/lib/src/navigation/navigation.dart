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

import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

/// Attribute keys owned by the SDK on navigation telemetry.
///
/// These are populated natively (`screen.name`, `navigation.name`,
/// `last.screen.name`) and the instrumentation `component`. They are stripped
/// from caller-supplied attributes before bridging so behavior is identical
/// across iOS (which strips natively) and Android (which does not).
const Set<String> _reservedNavigationAttributeKeys = {
  'component',
  'navigation.name',
  'screen.name',
  'last.screen.name',
};

/// Navigation tracking.
///
/// Manually track screen navigation events when automatic navigation
/// instrumentation is not available or sufficient.
///
/// For automatic tracking, install a [SplunkNavigatorObserver] on your app's
/// `Navigator` (e.g. `MaterialApp.navigatorObservers`).
class Navigation {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  /// Tracks a screen navigation event.
  ///
  /// Creates a navigation signal representing the screen view and updates the
  /// shared `screen.name` propagated to all other telemetry.
  ///
  /// [screenName] - Name of the screen being navigated to.
  /// [attributes] - Optional custom attributes attached to the navigation
  /// signal. When `null`, no attributes are sent (distinct from an empty
  /// [MutableAttributes], which sends an explicit empty set). SDK-reserved keys
  /// (`component`, `navigation.name`, `screen.name`, `last.screen.name`) are
  /// removed before sending.
  ///
  /// Example:
  /// ```dart
  /// await SplunkRum.instance.navigation.track(
  ///   screenName: 'HomeScreen',
  /// );
  /// ```
  Future<void> track({
    required String screenName,
    MutableAttributes? attributes,
  }) async => await _delegate.navigationTrack(
    screenName: screenName,
    attributes: _sanitize(attributes),
  );

  /// Removes SDK-reserved keys from caller-supplied attributes.
  ///
  /// Preserves the `null` vs. empty distinction: a `null` input stays `null`
  /// (no attributes sent), while a provided collection is returned with the
  /// reserved keys stripped (possibly empty).
  static MutableAttributes? _sanitize(MutableAttributes? attributes) {
    if (attributes == null) {
      return null;
    }

    final sanitized = <String, MutableAttributeValue>{};
    attributes.attributes.forEach((key, value) {
      if (_reservedNavigationAttributeKeys.contains(key)) {
        return;
      }

      sanitized[key] = value;
    });

    return MutableAttributes(attributes: sanitized);
  }
}
