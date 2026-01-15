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

import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

/// User tracking management.
///
/// Control user identification and tracking mode.
class User {
  /// Current user state.
  ///
  /// Provides access to the active user tracking mode.
  final state = UserState();

  /// User tracking preferences.
  ///
  /// Allows setting and getting user tracking mode preferences.
  final preferences = UserPreferences();
}

/// Current user state.
class UserState {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  /// Gets current user tracking mode.
  ///
  /// Returns the active tracking mode:
  /// - `UserTrackingMode.noTracking`: No user identifier generated.
  /// - `UserTrackingMode.anonymousTracking`: Generates anonymous user ID per session.
  Future<UserTrackingMode> getTrackingMode() async =>
      await _delegate.userStateGetUserTrackingMode();
}

/// User tracking preferences.
class UserPreferences {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  /// Gets user tracking mode preference.
  ///
  /// Returns the configured tracking mode preference, or `null` if not set.
  Future<UserTrackingMode?> getTrackingMode() async =>
      await _delegate.userPreferencesGetUserTrackingMode();

  /// Sets user tracking mode.
  ///
  /// [userTrackingMode] - Tracking mode to set:
  ///   - `UserTrackingMode.noTracking`: No user identifier generated.
  ///   - `UserTrackingMode.anonymousTracking`: Generates anonymous user ID per session.
  Future<void> setTrackingMode({
    required UserTrackingMode userTrackingMode,
  }) async =>
      await _delegate.userPreferencesSetUserTrackingMode(
        userTrackingMode: userTrackingMode,
      );
}
