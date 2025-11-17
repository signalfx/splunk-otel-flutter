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

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

abstract class SplunkOtelFlutterPlatformInterface extends PlatformInterface {

  SplunkOtelFlutterPlatformInterface(): super(token: _token);

  static final Object _token = Object();

  static SplunkOtelFlutterPlatformInterface? _instance;

  static SplunkOtelFlutterPlatformInterface get instance {
    return _instance ??= SplunkOtelFlutterPlatformImplementation.instance;
  }

  static set instance(SplunkOtelFlutterPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<void> install({required AgentConfiguration agentConfiguration, required List<ModuleConfiguration> moduleConfigurations});

  // Session replay
  Future<void> sessionReplayStart();
  Future<void> sessionReplayStop();
  Future<SessionReplayStatus> sessionReplayStateGetStatus();
  Future<RenderingMode> sessionReplayStateGetRenderingMode();
  Future<RenderingMode?> sessionReplayPreferencesGetRenderingMode();
  Future<void> sessionReplayPreferencesSetRenderingMode({required RenderingMode? renderingMode});
  Future<RecordingMaskList?> sessionReplayGetRecordingMask();
  Future<void> sessionReplaySetRecordingMask({required RecordingMaskList recordingMask});

  // State
  Future<String> stateGetAppName();
  Future<String> stateGetAppVersion();
  Future<Status> stateGetStatus();
  Future<EndpointConfiguration> stateGetEndpointConfiguration();
  Future<String> stateGetDeploymentEnvironment();
  Future<bool> stateGetIsDebugLoggingEnabled();
  Future<String?> stateGetInstrumentedProcessName();
  Future<bool> stateGetDeferredUntilForeground();

  // Session
  Future<String> sessionStateGetId();
  Future<double> sessionStateGetSamplingRate();

  // User
  Future<UserTrackingMode> userStateGetUserTrackingMode();
  Future<UserTrackingMode?> userPreferencesGetUserTrackingMode();
  Future<void> userPreferencesSetUserTrackingMode({required UserTrackingMode userTrackingMode});

  // Global attributes
  Future<MutableAttributeValue> globalAttributesGet({required String key});
  Future<MutableAttributes> globalAttributesGetAll();
  Future<void> globalAttributesRemove({required String key});
  Future<void> globalAttributesRemoveAll();
  Future<bool> globalAttributesContains({required String key});
  Future<void> globalAttributesSetString({required String key, required String value});
  Future<void> globalAttributesSetInt({required String key, required int value});
  Future<void> globalAttributesSetDouble({required String key, required double value});
  Future<void> globalAttributesSetBool({required String key, required bool value});
  Future<void> globalAttributesSetStringList({required String key, required List<String> value});
  Future<void> globalAttributesSetIntList({required String key, required List<int> value});
  Future<void> globalAttributesSetDoubleList({required String key, required List<double> value});
  Future<void> globalAttributesSetBoolList({required String key, required List<bool> value});
  Future<void> globalAttributesSetAll({required MutableAttributes attributes});
 }
