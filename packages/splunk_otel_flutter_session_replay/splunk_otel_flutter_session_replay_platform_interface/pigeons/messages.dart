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

import 'package:pigeon/pigeon.dart';


@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/pigeon/messages.pigeon.dart',
    dartPackageName: 'splunk_otel_flutter_session_replay_platform_interface',
    kotlinOut:
    '../splunk_otel_flutter_session_replay/android/src/main/kotlin/com/splunk/rum/flutter/GeneratedAndroidSplunkOtelFlutterSessionReplay.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.splunk.rum.flutter.sessionreplay',
    ),
    swiftOut:
    '../splunk_otel_flutter_session_replay/ios/splunk_otel_flutter_session_replay/Sources/splunk_otel_flutter_session_replay/SplunkOtelFlutterSessionReplayMessages.g.swift',
  ),
)

@HostApi()
abstract class SplunkOtelFlutterSessionReplayHostApi {
  @async
  void install();
}
