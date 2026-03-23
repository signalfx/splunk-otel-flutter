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
import 'package:splunk_otel_flutter_platform_interface/src/model/mutable_attributes.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/status.dart';
import 'package:splunk_otel_flutter_platform_interface/src/platform_interface/splunk_otel_flutter_platform_interface.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

class SplunkOtelFlutterPlatformImplementation
    extends SplunkOtelFlutterPlatformInterface {
  SplunkOtelFlutterPlatformImplementation._internal();

  static final SplunkOtelFlutterPlatformImplementation _instance =
      SplunkOtelFlutterPlatformImplementation._internal();

  static SplunkOtelFlutterPlatformImplementation get instance => _instance;

  final _api = SplunkOtelFlutterHostApi();

  @override
  Future<void> install({
    required AgentConfiguration agentConfiguration,
    required List<ModuleConfiguration> moduleConfigurations,
  }) async {
    // Core modules
    final navigationModuleConfiguration = moduleConfigurations
        .whereType<NavigationModuleConfiguration>()
        .cast<NavigationModuleConfiguration?>()
        .firstOrNull;

    final slowRenderingModuleConfiguration = moduleConfigurations
        .whereType<SlowRenderingModuleConfiguration>()
        .cast<SlowRenderingModuleConfiguration?>()
        .firstOrNull;

    final crashReportsModuleConfiguration = moduleConfigurations
        .whereType<CrashReportsModuleConfiguration>()
        .cast<CrashReportsModuleConfiguration?>()
        .firstOrNull;

    final interactionsModuleConfiguration = moduleConfigurations
        .whereType<InteractionsModuleConfiguration>()
        .cast<InteractionsModuleConfiguration?>()
        .firstOrNull;

    final networkMonitorModuleConfiguration = moduleConfigurations
        .whereType<NetworkMonitorModuleConfiguration>()
        .cast<NetworkMonitorModuleConfiguration?>()
        .firstOrNull;

    final applicationLifecycleModuleConfiguration = moduleConfigurations
        .whereType<ApplicationLifecycleModuleConfiguration>()
        .cast<ApplicationLifecycleModuleConfiguration?>()
        .firstOrNull;

    // Android-only modules
    final anrModuleConfiguration = moduleConfigurations
        .whereType<AnrModuleConfiguration>()
        .cast<AnrModuleConfiguration?>()
        .firstOrNull;

    final httpUrlModuleConfiguration = moduleConfigurations
        .whereType<HttpUrlModuleConfiguration>()
        .cast<HttpUrlModuleConfiguration?>()
        .firstOrNull;

    final okHttp3AutoModuleConfiguration = moduleConfigurations
        .whereType<OkHttp3AutoModuleConfiguration>()
        .cast<OkHttp3AutoModuleConfiguration?>()
        .firstOrNull;

    final networkInstrumentationModuleConfiguration = moduleConfigurations
        .whereType<NetworkInstrumentationModuleConfiguration>()
        .cast<NetworkInstrumentationModuleConfiguration?>()
        .firstOrNull;

    await _api.install(
      agentConfiguration: GeneratedAgentConfiguration(
        endpoint: agentConfiguration.endpointConfiguration?.toGeneratedEndpointConfiguration(),
        appName: agentConfiguration.appName,
        deploymentEnvironment: agentConfiguration.deploymentEnvironment,
        appVersion: agentConfiguration.appVersion,
        enableDebugLogging: agentConfiguration.enableDebugLogging,
        globalAttributes:
            agentConfiguration.globalAttributes?.toGeneratedMutableAttributes(),
        user: agentConfiguration.user.toGeneratedUserConfiguration(),
        session: GeneratedSessionConfiguration(
          samplingRate: agentConfiguration.session.samplingRate,
        ),
        instrumentedProcessName: agentConfiguration.instrumentedProcessName,
        deferredUntilForeground: agentConfiguration.deferredUntilForeground,
      ),

      // Core modules
      navigationModuleConfiguration: navigationModuleConfiguration == null
          ? null
          : GeneratedNavigationModuleConfiguration(
              isEnabled: navigationModuleConfiguration.isEnabled,
              isAutomatedTrackingEnabled:
                  navigationModuleConfiguration.isAutomatedTrackingEnabled,
            ),
      slowRenderingModuleConfiguration: slowRenderingModuleConfiguration == null
          ? null
          : GeneratedSlowRenderingModuleConfiguration(
              isEnabled: slowRenderingModuleConfiguration.isEnabled,
              intervalMillis:
                  slowRenderingModuleConfiguration.interval.inMilliseconds,
            ),
      crashReportsModuleConfiguration: crashReportsModuleConfiguration == null
          ? null
          : GeneratedCrashReportsModuleConfiguration(
              isEnabled: crashReportsModuleConfiguration.isEnabled,
            ),
      interactionsModuleConfiguration: interactionsModuleConfiguration == null
          ? null
          : GeneratedInteractionsModuleConfiguration(
              isEnabled: interactionsModuleConfiguration.isEnabled,
            ),
      networkMonitorModuleConfiguration:
          networkMonitorModuleConfiguration == null
              ? null
              : GeneratedNetworkMonitorModuleConfiguration(
                  isEnabled: networkMonitorModuleConfiguration.isEnabled,
                ),
      applicationLifecycleModuleConfiguration:
          applicationLifecycleModuleConfiguration == null
              ? null
              : GeneratedApplicationLifecycleModuleConfiguration(
                  isEnabled: applicationLifecycleModuleConfiguration.isEnabled,
                ),

      // Android-only modules
      anrModuleConfiguration: anrModuleConfiguration == null
          ? null
          : GeneratedAnrModuleConfiguration(
              isEnabled: anrModuleConfiguration.isEnabled,
            ),
      httpUrlModuleConfiguration: httpUrlModuleConfiguration == null
          ? null
          : GeneratedHttpUrlModuleConfiguration(
              isEnabled: httpUrlModuleConfiguration.isEnabled,
              capturedRequestHeaders:
                  httpUrlModuleConfiguration.capturedRequestHeaders,
              capturedResponseHeaders:
                  httpUrlModuleConfiguration.capturedResponseHeaders,
            ),
      okHttp3AutoModuleConfiguration: okHttp3AutoModuleConfiguration == null
          ? null
          : GeneratedOkHttp3AutoModuleConfiguration(
              isEnabled: okHttp3AutoModuleConfiguration.isEnabled,
              capturedRequestHeaders:
                  okHttp3AutoModuleConfiguration.capturedRequestHeaders,
              capturedResponseHeaders:
                  okHttp3AutoModuleConfiguration.capturedResponseHeaders,
            ),
      // iOS only modules
      networkInstrumentationModuleConfiguration:
          networkInstrumentationModuleConfiguration == null
              ? null
              : GeneratedNetworkInstrumentationModuleConfiguration(
                  isEnabled:
                      networkInstrumentationModuleConfiguration.isEnabled,
                  ignoreURLs: networkInstrumentationModuleConfiguration
                      .ignoreURLs
                      .toGeneratedList(),
                ),
    );
  }

  //State

  @override
  Future<String> stateGetAppName() async => await _api.stateGetAppName();

  @override
  Future<String> stateGetAppVersion() async => await _api.stateGetAppVersion();

  @override
  Future<bool> stateGetDeferredUntilForeground() async =>
      await _api.stateGetDeferredUntilForeground();

  @override
  Future<String> stateGetDeploymentEnvironment() async =>
      await _api.stateGetDeploymentEnvironment();

  @override
  Future<EndpointConfiguration?> stateGetEndpointConfiguration() async {
    final generatedConfiguration = await _api.stateGetEndpointConfiguration();

    return generatedConfiguration?.toEndpointConfiguration();
  }

  @override
  Future<String?> stateGetInstrumentedProcessName() async =>
      await _api.stateGetInstrumentedProcessName();

  @override
  Future<bool> stateGetIsDebugLoggingEnabled() async =>
      await _api.stateGetIsDebugLoggingEnabled();

  @override
  Future<Status> stateGetStatus() async {
    final generatedStatus = await _api.stateGetStatus();

    return generatedStatus.toStatus();
  }

  // Preferences

  @override
  Future<EndpointConfiguration?> preferencesGetEndpointConfiguration() async {
    final genEndpointConfig = await _api.preferencesGetEndpointConfiguration();

    return genEndpointConfig?.toEndpointConfiguration();
  }

  @override
  Future<void> preferencesSetEndpointConfiguration({
    required EndpointConfiguration endpointConfiguration,
  }) async {
    await _api.preferencesSetEndpointConfiguration(
      endpointConfiguration:
          endpointConfiguration.toGeneratedEndpointConfiguration(),
    );
  }

  // Session

  @override
  Future<String> sessionStateGetId() async => await _api.sessionStateGetId();

  @override
  Future<double> sessionStateGetSamplingRate() async =>
      await _api.sessionStateGetSamplingRate();

  // User

  @override
  Future<UserTrackingMode?> userPreferencesGetUserTrackingMode() async {
    final generatedUserTrackingMode =
        await _api.userPreferencesGetUserTrackingMode();

    if (generatedUserTrackingMode == null) {
      return null;
    }

    final userTrackingMode =
        generatedUserTrackingMode == GeneratedUserTrackingMode.noTracking
            ? UserTrackingMode.noTracking
            : UserTrackingMode.anonymousTracking;

    return userTrackingMode;
  }

  @override
  Future<void> userPreferencesSetUserTrackingMode({
    required UserTrackingMode userTrackingMode,
  }) async {
    await _api.userPreferencesSetUserTrackingMode(
      trackingMode: userTrackingMode.toGeneratedUserTrackingMode(),
    );
  }

  @override
  Future<UserTrackingMode> userStateGetUserTrackingMode() async {
    final generatedUserTrackingMode = await _api.userStateGetUserTrackingMode();

    final userTrackingMode =
        generatedUserTrackingMode == GeneratedUserTrackingMode.noTracking
            ? UserTrackingMode.noTracking
            : UserTrackingMode.anonymousTracking;

    return userTrackingMode;
  }

  // Global attributes

  @override
  Future<MutableAttributeValue?> globalAttributesGet({
    required String key,
  }) async {
    final generatedAttribute = await _api.globalAttributesGet(key: key);

    return generatedAttribute?.toMutableAttributeValue();
  }

  @override
  Future<MutableAttributes> globalAttributesGetAll() async {
    final generatedAttributes = await _api.globalAttributesGetAll();

    return generatedAttributes?.toMutableAttributes() ?? const MutableAttributes();
  }

  @override
  Future<void> globalAttributesRemove({
    required String key,
  }) async {
    await _api.globalAttributesRemove(key: key);
  }

  @override
  Future<void> globalAttributesRemoveAll() async {
    await _api.globalAttributesRemoveAll();
  }

  @override
  Future<bool> globalAttributesContains({
    required String key,
  }) async =>
      await _api.globalAttributesContains(key: key);

  @override
  Future<void> globalAttributesSetString({
    required String key,
    required String value,
  }) async {
    await _api.globalAttributesSetString(key: key, value: value);
  }

  @override
  Future<void> globalAttributesSetInt({
    required String key,
    required int value,
  }) async {
    await _api.globalAttributesSetInt(key: key, value: value);
  }

  @override
  Future<void> globalAttributesSetDouble({
    required String key,
    required double value,
  }) async {
    await _api.globalAttributesSetDouble(key: key, value: value);
  }

  @override
  Future<void> globalAttributesSetBool({
    required String key,
    required bool value,
  }) async {
    await _api.globalAttributesSetBool(key: key, value: value);
  }

  @override
  Future<void> globalAttributesSetStringList({
    required String key,
    required List<String> value,
  }) async {
    await _api.globalAttributesSetStringList(key: key, value: value);
  }

  @override
  Future<void> globalAttributesSetIntList({
    required String key,
    required List<int> value,
  }) async {
    await _api.globalAttributesSetIntList(key: key, value: value);
  }

  @override
  Future<void> globalAttributesSetDoubleList({
    required String key,
    required List<double> value,
  }) async {
    await _api.globalAttributesSetDoubleList(key: key, value: value);
  }

  @override
  Future<void> globalAttributesSetBoolList({
    required String key,
    required List<bool> value,
  }) async {
    await _api.globalAttributesSetBoolList(key: key, value: value);
  }

  @override
  Future<void> globalAttributesSetAll({
    required MutableAttributes attributes,
  }) async {
    await _api.globalAttributesSetAll(
      value: attributes.toGeneratedMutableAttributes(),
    );
  }

  // Custom Tracking

  @override
  Future<void> customTrackingTrackCustomEvent({
    required String name,
    required MutableAttributes attributes,
  }) async {
    await _api.customTrackingTrackCustomEvent(
      name: name,
      attributes: attributes.toGeneratedMutableAttributes(),
    );
  }

  @override
  Future<int> customTrackingStartWorkflow({
    required String workflowName,
  }) async {
    return await _api.customTrackingStartWorkflow(
      workflowName: workflowName,
    );
  }

  @override
  Future<void> customTrackingEndWorkflow({
    required int handle,
  }) async {
    await _api.customTrackingEndWorkflow(
      handle: handle,
    );
  }

  // Navigation

  @override
  Future<void> navigationTrack({required String screenName}) async {
    await _api.navigationTrack(
      screenName: screenName,
    );
  }
}
