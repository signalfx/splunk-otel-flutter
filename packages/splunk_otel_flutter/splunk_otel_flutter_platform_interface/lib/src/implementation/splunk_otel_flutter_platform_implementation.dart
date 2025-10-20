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

import 'package:splunk_otel_flutter_platform_interface/src/model/agent_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/module_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/platform_interface/splunk_otel_flutter_platform_interface.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

class SplunkOtelFlutterPlatformImplementation
    extends SplunkOtelFlutterPlatformInterface {
  SplunkOtelFlutterPlatformImplementation._();

  static SplunkOtelFlutterPlatformImplementation get instance {
    return SplunkOtelFlutterPlatformImplementation._();
  }

  final _api = SplunkOtelFlutterHostApi();

  @override
  Future<void> install({
    required AgentConfiguration agentConfiguration,
    required List<ModuleConfiguration> moduleConfigurations,
  }) async {
    final navigationModuleConfiguration = moduleConfigurations.firstWhere(
      (element) => element is NavigationModuleConfiguration,
      orElse: () => NavigationModuleConfiguration(),
    ) as NavigationModuleConfiguration;

    final slowRenderingModuleConfiguration = moduleConfigurations.firstWhere(
      (element) => element is SlowRenderingModuleConfiguration,
      orElse: () => SlowRenderingModuleConfiguration(),
    ) as SlowRenderingModuleConfiguration;

    //TODO more configurations

    await _api.install(
      agentConfiguration: GeneratedAgentConfiguration(
          endpoint: GeneratedEndpointConfiguration(
            realm: agentConfiguration.endpoint.realm,
            rumAccessToken: agentConfiguration.endpoint.rumAccessToken,
          ),
          appName: agentConfiguration.appName,
          deploymentEnvironment: agentConfiguration.deploymentEnvironment,
          appVersion: agentConfiguration.appVersion,
          enableDebugLogging: agentConfiguration.enableDebugLogging,
          globalAttributes: agentConfiguration.globalAttributes,     // TODO
          user: agentConfiguration.user.toGeneratedUserConfiguration(),
          session: GeneratedSessionConfiguration(
              samplingRate: agentConfiguration.session.samplingRate),
          instrumentedProcessName: agentConfiguration.instrumentedProcessName,
          deferredUntilForeground: agentConfiguration.deferredUntilForeground),
      navigationModuleConfiguration: GeneratedNavigationModuleConfiguration(
        isEnabled: navigationModuleConfiguration.isEnabled,
        isAutomatedTrackingEnabled:
            navigationModuleConfiguration.isAutomatedTrackingEnabled,
      ),
      slowRenderingModuleConfiguration:
          GeneratedSlowRenderingModuleConfiguration(
        isEnabled: slowRenderingModuleConfiguration.isEnabled,
        intervalMillis:
            slowRenderingModuleConfiguration.interval.inMilliseconds,
      ),
    );
  }

  @override
  Future<void> sessionReplayStart() async {
    await _api.sessionReplayStart();
  }

  @override
  Future<String> getSessionId() async {
    return await _api.getSessionId();
  }
}
