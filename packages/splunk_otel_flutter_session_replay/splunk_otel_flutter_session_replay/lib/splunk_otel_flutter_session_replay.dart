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

library splunk_otel_flutter_session_replay;

import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';
import 'package:splunk_otel_flutter_session_replay_platform_interface/implementation/splunk_otel_flutter_session_replay_platform_implementation.dart';

export 'package:splunk_otel_flutter_platform_interface/src/model/session_replay.dart'
    show
        SessionReplayStatus,
        RecordingMaskList,
        RecordingMaskElement,
        RecordingMaskType;

/// Splunk Session Replay SDK entry point.
///
/// Use `SplunkSessionReplay.instance` to access session replay functionality
/// after the core Splunk RUM agent has been initialized.
///
/// Example:
/// ```dart
/// await SplunkRum.instance.install(
///   agentConfiguration: AgentConfiguration(...),
///   moduleConfigurations: [],
/// );
///
/// await SplunkSessionReplay.instance.start();
/// ```
class SplunkSessionReplay {
  static final SplunkSessionReplay _instance = SplunkSessionReplay._internal();

  SplunkSessionReplay._internal();

  /// SDK singleton instance.
  static SplunkSessionReplay get instance => _instance;

  final _delegate =
      SplunkOtelFlutterSessionReplayPlatformImplementation.instance;

  /// Starts session replay recording.
  Future<void> start() async => await _delegate.start();

  /// Stops session replay recording.
  Future<void> stop() async => await _delegate.stop();

  /// Returns the current session replay recording status.
  Future<SessionReplayStatus> getStatus() async => await _delegate.getStatus();

  /// Returns the current recording mask, or `null` if none is set.
  Future<RecordingMaskList?> getRecordingMask() async =>
      await _delegate.getRecordingMask();

  /// Sets the recording mask used to hide or obscure sensitive content.
  ///
  /// Pass `null` to clear the current mask.
  Future<void> setRecordingMask(
          {required RecordingMaskList? recordingMask}) async =>
      await _delegate.setRecordingMask(recordingMask: recordingMask);
}
