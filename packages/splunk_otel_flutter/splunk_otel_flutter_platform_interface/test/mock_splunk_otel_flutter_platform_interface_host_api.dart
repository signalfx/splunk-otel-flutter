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
  Future<void> Function()? sessionReplayStopHandler;
  Future<GeneratedSessionReplayStatus> Function()? sessionReplayStateGetStatusHandler;
  Future<GeneratedRenderingMode> Function()? sessionReplayStateGetRenderingModeHandler;
  Future<GeneratedRenderingMode?> Function()? sessionReplayPreferencesGetRenderingModeHandler;
  Future<void> Function(GeneratedRenderingMode?)? sessionReplayPreferencesSetRenderingModeHandler;
  Future<GeneratedRecordingMaskList?> Function()? sessionReplayGetRecordingMaskHandler;
  Future<void> Function(GeneratedRecordingMaskList?)? sessionReplaySetRecordingMaskHandler;

  Future<String> Function()? stateGetAppNameHandler;
  Future<String> Function()? stateGetAppVersionHandler;
  Future<GeneratedStatus> Function()? stateGetStatusHandler;
  Future<GeneratedEndpointConfiguration> Function()? stateGetEndpointConfigurationHandler;
  Future<String> Function()? stateGetDeploymentEnvironmentHandler;
  Future<bool> Function()? stateGetIsDebugLoggingEnabledHandler;
  Future<String?> Function()? stateGetInstrumentedProcessNameHandler;
  Future<bool> Function()? stateGetDeferredUntilForegroundHandler;

  Future<GeneratedEndpointConfiguration?> Function()? preferencesGetEndpointConfigurationHandler;

  Future<String> Function()? sessionStateGetIdHandler;
  Future<double> Function()? sessionStateGetSamplingRateHandler;

  Future<GeneratedUserTrackingMode> Function()? userStateGetUserTrackingModeHandler;
  Future<GeneratedUserTrackingMode?> Function()? userPreferencesGetUserTrackingModeHandler;
  Future<void> Function(GeneratedUserTrackingMode)? userPreferencesSetUserTrackingModeHandler;

  Future<Object?> Function(String)? globalAttributesGetHandler;
  Future<GeneratedMutableAttributes?> Function()? globalAttributesGetAllHandler;
  Future<void> Function(String)? globalAttributesRemoveHandler;
  Future<void> Function()? globalAttributesRemoveAllHandler;
  Future<bool> Function(String)? globalAttributesContainsHandler;
  Future<void> Function(String, String)? globalAttributesSetStringHandler;
  Future<void> Function(String, int)? globalAttributesSetIntHandler;
  Future<void> Function(String, double)? globalAttributesSetDoubleHandler;
  Future<void> Function(String, bool)? globalAttributesSetBoolHandler;
  Future<void> Function(String, List<String>)? globalAttributesSetStringListHandler;
  Future<void> Function(String, List<int>)? globalAttributesSetIntListHandler;
  Future<void> Function(String, List<double>)? globalAttributesSetDoubleListHandler;
  Future<void> Function(String, List<bool>)? globalAttributesSetBoolListHandler;
  Future<void> Function(GeneratedMutableAttributes)? globalAttributesSetAllHandler;

  Future<void> Function(String, GeneratedMutableAttributes)? customTrackingTrackCustomEventHandler;
  Future<int> Function(String)? customTrackingStartWorkflowHandler;
  Future<void> Function(int)? customTrackingEndWorkflowHandler;

  Future<void> Function(String)? navigationTrackHandler;

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
  Future<String> stateGetAppName() async {
    if (stateGetAppNameHandler != null) {
      return stateGetAppNameHandler!();
    }
    return 'MockApp';
  }

  @override
  Future<String> stateGetAppVersion() async {
    if (stateGetAppVersionHandler != null) {
      return stateGetAppVersionHandler!();
    }
    return '1.0.0';
  }

  @override
  Future<GeneratedStatus> stateGetStatus() async {
    if (stateGetStatusHandler != null) {
      return stateGetStatusHandler!();
    }
    return GeneratedStatus.running;
  }

  @override
  Future<GeneratedEndpointConfiguration> stateGetEndpointConfiguration() async {
    if (stateGetEndpointConfigurationHandler != null) {
      return stateGetEndpointConfigurationHandler!();
    }
    return GeneratedEndpointConfiguration(realm: 'us0', rumAccessToken: 'token');
  }

  @override
  Future<String> stateGetDeploymentEnvironment() async {
    if (stateGetDeploymentEnvironmentHandler != null) {
      return stateGetDeploymentEnvironmentHandler!();
    }
    return 'production';
  }

  @override
  Future<bool> stateGetIsDebugLoggingEnabled() async {
    if (stateGetIsDebugLoggingEnabledHandler != null) {
      return stateGetIsDebugLoggingEnabledHandler!();
    }
    return false;
  }

  @override
  Future<String?> stateGetInstrumentedProcessName() async {
    if (stateGetInstrumentedProcessNameHandler != null) {
      return stateGetInstrumentedProcessNameHandler!();
    }
    return null;
  }

  @override
  Future<bool> stateGetDeferredUntilForeground() async {
    if (stateGetDeferredUntilForegroundHandler != null) {
      return stateGetDeferredUntilForegroundHandler!();
    }
    return false;
  }

  @override
  Future<String> sessionStateGetId() async {
    if (sessionStateGetIdHandler != null) {
      return sessionStateGetIdHandler!();
    }
    return 'session-id-123';
  }

  @override
  Future<double> sessionStateGetSamplingRate() async {
    if (sessionStateGetSamplingRateHandler != null) {
      return sessionStateGetSamplingRateHandler!();
    }
    return 1.0;
  }

  @override
  Future<GeneratedUserTrackingMode> userStateGetUserTrackingMode() async {
    if (userStateGetUserTrackingModeHandler != null) {
      return userStateGetUserTrackingModeHandler!();
    }
    return GeneratedUserTrackingMode.noTracking;
  }

  @override
  Future<GeneratedUserTrackingMode?> userPreferencesGetUserTrackingMode() async {
    if (userPreferencesGetUserTrackingModeHandler != null) {
      return userPreferencesGetUserTrackingModeHandler!();
    }
    return null;
  }

  @override
  Future<void> userPreferencesSetUserTrackingMode({required GeneratedUserTrackingMode trackingMode}) async {
    if (userPreferencesSetUserTrackingModeHandler != null) {
      return userPreferencesSetUserTrackingModeHandler!(trackingMode);
    }
  }

  @override
  Future<Object?> globalAttributesGet({required String key}) async {
    if (globalAttributesGetHandler != null) {
      return globalAttributesGetHandler!(key);
    }
    return null;
  }

  @override
  Future<GeneratedMutableAttributes?> globalAttributesGetAll() async {
    if (globalAttributesGetAllHandler != null) {
      return globalAttributesGetAllHandler!();
    }
    return null;
  }

  @override
  Future<void> globalAttributesRemove({required String key}) async {
    if (globalAttributesRemoveHandler != null) {
      return globalAttributesRemoveHandler!(key);
    }
  }

  @override
  Future<void> globalAttributesRemoveAll() async {
    if (globalAttributesRemoveAllHandler != null) {
      return globalAttributesRemoveAllHandler!();
    }
  }

  @override
  Future<bool> globalAttributesContains({required String key}) async {
    if (globalAttributesContainsHandler != null) {
      return globalAttributesContainsHandler!(key);
    }
    return false;
  }

  @override
  Future<void> globalAttributesSetString({required String key, required String value}) async {
    if (globalAttributesSetStringHandler != null) {
      return globalAttributesSetStringHandler!(key, value);
    }
  }

  @override
  Future<void> globalAttributesSetInt({required String key, required int value}) async {
    if (globalAttributesSetIntHandler != null) {
      return globalAttributesSetIntHandler!(key, value);
    }
  }

  @override
  Future<void> globalAttributesSetDouble({required String key, required double value}) async {
    if (globalAttributesSetDoubleHandler != null) {
      return globalAttributesSetDoubleHandler!(key, value);
    }
  }

  @override
  Future<void> globalAttributesSetBool({required String key, required bool value}) async {
    if (globalAttributesSetBoolHandler != null) {
      return globalAttributesSetBoolHandler!(key, value);
    }
  }

  @override
  Future<void> globalAttributesSetStringList({required String key, required List<String> value}) async {
    if (globalAttributesSetStringListHandler != null) {
      return globalAttributesSetStringListHandler!(key, value);
    }
  }

  @override
  Future<void> globalAttributesSetIntList({required String key, required List<int> value}) async {
    if (globalAttributesSetIntListHandler != null) {
      return globalAttributesSetIntListHandler!(key, value);
    }
  }

  @override
  Future<void> globalAttributesSetDoubleList({required String key, required List<double> value}) async {
    if (globalAttributesSetDoubleListHandler != null) {
      return globalAttributesSetDoubleListHandler!(key, value);
    }
  }

  @override
  Future<void> globalAttributesSetBoolList({required String key, required List<bool> value}) async {
    if (globalAttributesSetBoolListHandler != null) {
      return globalAttributesSetBoolListHandler!(key, value);
    }
  }

  @override
  Future<void> globalAttributesSetAll({required GeneratedMutableAttributes value}) async {
    if (globalAttributesSetAllHandler != null) {
      return globalAttributesSetAllHandler!(value);
    }
  }

  @override
  Future<void> customTrackingTrackCustomEvent({required String name, required GeneratedMutableAttributes attributes}) async {
    if (customTrackingTrackCustomEventHandler != null) {
      return customTrackingTrackCustomEventHandler!(name, attributes);
    }
  }

  @override
  Future<int> customTrackingStartWorkflow({required String workflowName}) async {
    if (customTrackingStartWorkflowHandler != null) {
      return customTrackingStartWorkflowHandler!(workflowName);
    }
    return 1; // Return a default handle for testing
  }

  @override
  Future<void> customTrackingEndWorkflow({required int handle}) async {
    if (customTrackingEndWorkflowHandler != null) {
      return customTrackingEndWorkflowHandler!(handle);
    }
  }

  @override
  Future<void> navigationTrack({required String screenName}) async {
    if (navigationTrackHandler != null) {
      return navigationTrackHandler!(screenName);
    }
  }

  @override
  Future<GeneratedEndpointConfiguration?> preferencesGetEndpointConfiguration() async {
    if (preferencesGetEndpointConfigurationHandler != null) {
      return preferencesGetEndpointConfigurationHandler!();
    }
    return null;
  }

}