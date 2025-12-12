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

// Mock implementation


import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';
import 'pigeon/test_api.dart';

class MockSplunkOtelFlutterPlatformInterfaceHostApi implements TestSplunkOtelFlutterHostApi {
  Future<void> Function(
      GeneratedAgentConfiguration agentConfiguration,

      // Core configurations
      GeneratedNavigationModuleConfiguration? navigationModuleConfiguration,
      GeneratedSlowRenderingModuleConfiguration? slowRenderingModuleConfiguration,
      GeneratedCrashReportsModuleConfiguration? crashReportsModuleConfiguration,
      GeneratedInteractionsModuleConfiguration? interactionsModuleConfiguration,
      GeneratedNetworkMonitorModuleConfiguration? networkMonitorModuleConfiguration,

      // Android-only configurations
      GeneratedAnrModuleConfiguration? anrModuleConfiguration,
      GeneratedHttpUrlModuleConfiguration? httpUrlModuleConfiguration,
      GeneratedOkHttp3AutoModuleConfiguration? okHttp3AutoModuleConfiguration,

      // iOS-only configurations
      GeneratedNetworkInstrumentationModuleConfiguration?  networkInstrumentationModuleConfiguration
      )? installHandler;

  Future<void> Function()? sessionReplayStartHandler;
  Future<String> Function()? getSessionIdHandler;

  @override
  Future<void> install({
    required GeneratedAgentConfiguration agentConfiguration,
    // Core configurations
    required GeneratedNavigationModuleConfiguration? navigationModuleConfiguration,
    required GeneratedSlowRenderingModuleConfiguration? slowRenderingModuleConfiguration,
    required GeneratedCrashReportsModuleConfiguration? crashReportsModuleConfiguration,
    required GeneratedInteractionsModuleConfiguration? interactionsModuleConfiguration,
    required GeneratedNetworkMonitorModuleConfiguration? networkMonitorModuleConfiguration,

    // Android-only configurations
    required GeneratedAnrModuleConfiguration? anrModuleConfiguration,
    required GeneratedHttpUrlModuleConfiguration? httpUrlModuleConfiguration,
    required GeneratedOkHttp3AutoModuleConfiguration? okHttp3AutoModuleConfiguration,

    // iOS-only configurations
    required GeneratedNetworkInstrumentationModuleConfiguration?  networkInstrumentationModuleConfiguration
  }) async {
    if (installHandler != null) {
      return installHandler!(
        agentConfiguration,
        navigationModuleConfiguration,
        slowRenderingModuleConfiguration,
        crashReportsModuleConfiguration,
        interactionsModuleConfiguration,
        networkMonitorModuleConfiguration,
        anrModuleConfiguration,
        httpUrlModuleConfiguration,
        okHttp3AutoModuleConfiguration,
        networkInstrumentationModuleConfiguration,
      );
    }
  }

  @override
  Future<void> sessionReplayStart() async {
    if (sessionReplayStartHandler != null) {
      return sessionReplayStartHandler!();
    }
  }

  @override
  Future<bool> globalAttributesContains({required String key}) {
    // TODO: implement globalAttributesContains
    throw UnimplementedError();
  }

  @override
  Future<dynamic> globalAttributesGet({required String key}) {
    // TODO: implement globalAttributesGet
    throw UnimplementedError();
  }

  @override
  Future<GeneratedMutableAttributes?> globalAttributesGetAll() {
    // TODO: implement globalAttributesGetAll
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesRemove({required String key}) {
    // TODO: implement globalAttributesRemove
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesRemoveAll() {
    // TODO: implement globalAttributesRemoveAll
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesSetAll({required GeneratedMutableAttributes value}) {
    // TODO: implement globalAttributesSetAll
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesSetBool({required String key, required bool? value}) {
    // TODO: implement globalAttributesSetBool
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesSetBoolList({required String key, required List<bool>? value}) {
    // TODO: implement globalAttributesSetBoolList
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesSetDouble({required String key, required double? value}) {
    // TODO: implement globalAttributesSetDouble
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesSetDoubleList({required String key, required List<double>? value}) {
    // TODO: implement globalAttributesSetDoubleList
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesSetInt({required String key, required int? value}) {
    // TODO: implement globalAttributesSetInt
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesSetIntList({required String key, required List<int>? value}) {
    // TODO: implement globalAttributesSetIntList
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesSetString({required String key, required String? value}) {
    // TODO: implement globalAttributesSetString
    throw UnimplementedError();
  }

  @override
  Future<void> globalAttributesSetStringList({required String key, required List<String>? value}) {
    // TODO: implement globalAttributesSetStringList
    throw UnimplementedError();
  }

  @override
  Future<GeneratedRecordingMaskList?> sessionReplayGetRecordingMask() {
    // TODO: implement sessionReplayGetRecordingMask
    throw UnimplementedError();
  }

  @override
  Future<GeneratedRenderingMode?> sessionReplayPreferencesGetRenderingMode() {
    // TODO: implement sessionReplayPreferencesGetRenderingMode
    throw UnimplementedError();
  }

  @override
  Future<void> sessionReplayPreferencesSetRenderingMode({required GeneratedRenderingMode? renderingMode}) {
    // TODO: implement sessionReplayPreferencesSetRenderingMode
    throw UnimplementedError();
  }

  @override
  Future<void> sessionReplaySetRecordingMask({required GeneratedRecordingMaskList? recordingMask}) {
    // TODO: implement sessionReplaySetRecordingMask
    throw UnimplementedError();
  }

  @override
  Future<GeneratedRenderingMode> sessionReplayStateGetRenderingMode() {
    // TODO: implement sessionReplayStateGetRenderingMode
    throw UnimplementedError();
  }

  @override
  Future<GeneratedSessionReplayStatus> sessionReplayStateGetStatus() {
    // TODO: implement sessionReplayStateGetStatus
    throw UnimplementedError();
  }

  @override
  Future<void> sessionReplayStop() {
    // TODO: implement sessionReplayStop
    throw UnimplementedError();
  }

  @override
  Future<String> sessionStateGetId() {
    // TODO: implement sessionStateGetId
    throw UnimplementedError();
  }

  @override
  Future<double> sessionStateGetSamplingRate() {
    // TODO: implement sessionStateGetSamplingRate
    throw UnimplementedError();
  }

  @override
  Future<String> stateGetAppName() {
    // TODO: implement stateGetAppName
    throw UnimplementedError();
  }

  @override
  Future<String> stateGetAppVersion() {
    // TODO: implement stateGetAppVersion
    throw UnimplementedError();
  }

  @override
  Future<bool> stateGetDeferredUntilForeground() {
    // TODO: implement stateGetDeferredUntilForeground
    throw UnimplementedError();
  }

  @override
  Future<String> stateGetDeploymentEnvironment() {
    // TODO: implement stateGetDeploymentEnvironment
    throw UnimplementedError();
  }

  @override
  Future<GeneratedEndpointConfiguration> stateGetEndpointConfiguration() {
    // TODO: implement stateGetEndpointConfiguration
    throw UnimplementedError();
  }

  @override
  Future<String?> stateGetInstrumentedProcessName() {
    // TODO: implement stateGetInstrumentedProcessName
    throw UnimplementedError();
  }

  @override
  Future<bool> stateGetIsDebugLoggingEnabled() {
    // TODO: implement stateGetIsDebugLoggingEnabled
    throw UnimplementedError();
  }

  @override
  Future<GeneratedStatus> stateGetStatus() {
    // TODO: implement stateGetStatus
    throw UnimplementedError();
  }

  @override
  Future<GeneratedUserTrackingMode?> userPreferencesGetUserTrackingMode() {
    // TODO: implement userPreferencesGetUserTrackingMode
    throw UnimplementedError();
  }

  @override
  Future<void> userPreferencesSetUserTrackingMode({required GeneratedUserTrackingMode? trackingMode}) {
    // TODO: implement userPreferencesSetUserTrackingMode
    throw UnimplementedError();
  }

  @override
  Future<GeneratedUserTrackingMode> userStateGetUserTrackingMode() {
    // TODO: implement userStateGetUserTrackingMode
    throw UnimplementedError();
  }

  @override
  Future<void> customTrackingTrackCustomEvent({required String name, required GeneratedMutableAttributes attributes}) {
    // TODO: implement customTrackingTrackCustomEvent
    throw UnimplementedError();
  }
  @override
  Future<void> customTrackingTrackWorkflow({required String workflowName}) {
    // TODO: implement customTrackingTrackWorkflow
    throw UnimplementedError();
  }

  @override
  Future<void> navigationTrack({required String screenName}) {
    // TODO: implement navigationTrack
    throw UnimplementedError();
  }
  
}