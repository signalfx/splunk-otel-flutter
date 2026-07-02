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

import 'package:flutter/widgets.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

/// Installs the Splunk RUM agent for the navigation-lab entrypoints.
///
/// Pass credentials via --dart-define:
///   --dart-define=REALM=your_realm
///   --dart-define=RUM_ACCESS_TOKEN=your_token
///
/// Native automatic navigation tracking is intentionally OFF; the Dart-side
/// [SplunkNavigatorObserver] is the source of screen changes.
Future<void> installSplunkRum({required String appName}) async {
  const String realm = String.fromEnvironment('REALM');
  const String rumAccessToken = String.fromEnvironment('RUM_ACCESS_TOKEN');

  WidgetsFlutterBinding.ensureInitialized();

  await SplunkRum.instance.install(
    agentConfiguration: AgentConfiguration(
      endpoint: EndpointConfiguration.forRum(
        realm: realm,
        rumAccessToken: rumAccessToken,
      ),
      appName: appName,
      deploymentEnvironment: 'dev',
      enableDebugLogging: true,
    ),
    moduleConfigurations: [
      NavigationModuleConfiguration(
        isEnabled: true,
        isAutomatedTrackingEnabled: false,
      ),
      CrashReportsModuleConfiguration(isEnabled: true),
      SessionReplayModuleConfiguration(samplingRate: 1.0),
    ],
  );

  await SplunkSessionReplay.instance.start();
  debugPrint('Session replay started');

  final sessionId = await SplunkRum.instance.session.state.getId();

  debugPrint('-------------');
  debugPrint('Session id: $sessionId');
}
