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

import 'package:splunk_otel_flutter/src/custom_tracking.dart';
import 'package:splunk_otel_flutter/src/global_attributes.dart';
import 'package:splunk_otel_flutter/src/navigation.dart';
import 'package:splunk_otel_flutter/src/preferences.dart';
import 'package:splunk_otel_flutter/src/session.dart';
import 'package:splunk_otel_flutter/src/session_replay.dart';
import 'package:splunk_otel_flutter/src/state.dart';
import 'package:splunk_otel_flutter/src/user.dart';
import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class SplunkOtelFlutter {
  static final SplunkOtelFlutter _instance = SplunkOtelFlutter._internal();

  SplunkOtelFlutter._internal();

  static SplunkOtelFlutter get instance => _instance;

  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  final session = Session();
  final state = State();
  final user = User();
  final sessionReplay = SessionReplay();
  final globalAttributes = GlobalAttributes();
  final customTracking = CustomTracking();
  final navigation = Navigation();
  final preferences = Preferences();

  Future<void> install({
    required AgentConfiguration agentConfiguration,
    required List<ModuleConfiguration> moduleConfigurations,
  }) async {
    await _delegate.install(
      agentConfiguration: agentConfiguration,
      moduleConfigurations: moduleConfigurations,
    );
  }
}
