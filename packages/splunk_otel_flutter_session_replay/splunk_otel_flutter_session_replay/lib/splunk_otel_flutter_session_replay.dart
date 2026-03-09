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

/// Splunk session replay module for Flutter applications.
///
/// This library provides session recording and replay capabilities, allowing you
/// to capture and analyze user interactions for debugging and optimization.
library splunk_otel_flutter_session_replay;

import 'package:splunk_otel_flutter_session_replay_platform_interface/implementation/splunk_otel_flutter_session_replay_platform_implementation.dart';

/// Splunk Session Replay SDK entry point.
///
/// Use `SplunkSessionReplay.instance.startSessionReplay()` to start recording
/// after the core Splunk RUM agent has been initialized.
///
/// Example:
/// ```dart
/// // First, initialize the core RUM agent
/// await SplunkRum.instance.install(
///   agentConfiguration: AgentConfiguration(...),
///   moduleConfigurations: [],
/// );
///
/// // Then start session replay
/// await SplunkSessionReplay.instance.startSessionReplay();
/// ```
class SplunkSessionReplay {
  static final SplunkSessionReplay _instance = SplunkSessionReplay._internal();

  SplunkSessionReplay._internal();

  /// SDK singleton instance.
  static SplunkSessionReplay get instance => _instance;

  final _delegate =
      SplunkOtelFlutterSessionReplayPlatformImplementation.instance;

  /// Starts session replay recording.
  ///
  /// This delegates to the native SDK's session replay start mechanism.
  /// The core Splunk RUM agent must be initialized first via
  /// `SplunkRum.instance.install()` before calling this method.
  ///
  /// On Android, this calls `SplunkRum.instance.sessionReplay.start()`
  /// which accesses the shared native singleton.
  Future<void> startSessionReplay() async {
    await _delegate.startSessionReplay();
  }
}