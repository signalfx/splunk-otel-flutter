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

/// Session management.
///
/// Provides access to current session ID and sampling rate.
class Session {
  /// Current session state.
  ///
  /// Provides access to session ID and sampling rate.
  final state = SessionState();
}

/// Current session state.
class SessionState {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  /// Gets unique session identifier.
  ///
  /// Returns the current session ID string.
  Future<String> getId() async => await _delegate.sessionStateGetId();

  /// Gets session sampling rate.
  ///
  /// Returns a value between 0.0 and 1.0 indicating the sampling rate
  /// for the current session.
  Future<double> getSamplingRate() async =>
      await _delegate.sessionStateGetSamplingRate();
}
