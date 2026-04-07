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

library splunk_otel_flutter_session_replay_platform_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';
import 'package:splunk_otel_flutter_session_replay_platform_interface/implementation/splunk_otel_flutter_session_replay_platform_implementation.dart';

abstract class SplunkOtelFlutterSessionReplayPlatformInterface extends PlatformInterface {

  SplunkOtelFlutterSessionReplayPlatformInterface(): super(token: _token);

  static final Object _token = Object();

  static SplunkOtelFlutterSessionReplayPlatformInterface? _instance;

  static SplunkOtelFlutterSessionReplayPlatformInterface get instance {
    return _instance ??= SplunkOtelFlutterSessionReplayPlatformImplementation.instance;
  }

  static set instance(SplunkOtelFlutterSessionReplayPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<void> sessionReplayStart();
  Future<void> sessionReplayStop();
  Future<SessionReplayStatus> sessionReplayStateGetStatus();
  Future<RecordingMaskList?> sessionReplayGetRecordingMask();
  Future<void> sessionReplaySetRecordingMask({required RecordingMaskList? recordingMask});
}
