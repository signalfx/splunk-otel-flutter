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

import 'package:splunk_otel_flutter_session_replay_platform_interface/platform_interface/splunk_otel_flutter_session_replay_platform_interface.dart';

/// Example demonstrating the Splunk session replay platform interface.
///
/// Note: This is a platform interface package. Actual functionality is
/// provided by platform-specific implementations.
void main() async {
  // Get the platform interface instance
  final platformInterface =
      SplunkOtelFlutterSessionReplayPlatformInterface.instance;

  // ignore: avoid_print
  print(
      'Session replay platform interface loaded: ${platformInterface.runtimeType}');

  // Start session replay recording (requires core RUM agent to be initialized)
  // await platformInterface.startSessionReplay();

  // ignore: avoid_print
  print('Session replay example completed!');
}
