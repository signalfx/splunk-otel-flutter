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

/// Platform interface for Splunk session replay functionality.
///
/// This library defines the API contract that platform-specific implementations
/// (iOS, Android) must fulfill to provide session recording and replay capabilities.
library splunk_otel_flutter_session_replay_platform_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:splunk_otel_flutter_session_replay_platform_interface/implementation/splunk_otel_flutter_session_replay_platform_implementation.dart';

/// The interface that platform implementations of splunk_otel_flutter_session_replay must extend.
///
/// Defines the API contract for session replay functionality across different platforms.
abstract class SplunkOtelFlutterSessionReplayPlatformInterface extends PlatformInterface {

  /// Creates a new instance with the verification token.
  SplunkOtelFlutterSessionReplayPlatformInterface(): super(token: _token);

  static final Object _token = Object();

  static SplunkOtelFlutterSessionReplayPlatformInterface? _instance;

  /// The default instance of [SplunkOtelFlutterSessionReplayPlatformInterface].
  static SplunkOtelFlutterSessionReplayPlatformInterface get instance {
    return _instance ??= SplunkOtelFlutterSessionReplayPlatformImplementation.instance;
  }

  /// Sets the default instance of [SplunkOtelFlutterSessionReplayPlatformInterface].
  ///
  /// This should only be used for testing or providing a custom implementation.
  static set instance(SplunkOtelFlutterSessionReplayPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Starts session replay recording.
  ///
  /// Delegates to the native SDK's session replay start mechanism.
  /// Requires that the core Splunk RUM agent has been initialized first
  /// via [SplunkRum.instance.install()].
  Future<void> startSessionReplay();
}
