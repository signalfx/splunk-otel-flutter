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

/// The interface that platform implementations of splunk_otel_flutter must extend.
///
/// This abstract class defines the API contract that platform-specific implementations
/// (iOS, Android) must fulfill to provide Splunk OpenTelemetry functionality.
abstract class SplunkOtelFlutterPlatformInterface extends PlatformInterface {
  /// Creates a new instance with the verification token.
  SplunkOtelFlutterPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static SplunkOtelFlutterPlatformInterface? _instance;

  /// The default instance of [SplunkOtelFlutterPlatformInterface].
  static SplunkOtelFlutterPlatformInterface get instance {
    return _instance ??= SplunkOtelFlutterPlatformImplementation.instance;
  }

  /// Sets the default instance of [SplunkOtelFlutterPlatformInterface].
  ///
  /// This should only be used for testing or providing a custom implementation.
  static set instance(SplunkOtelFlutterPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Installs and initializes the Splunk agent with the given configuration.
  ///
  /// Must be called before using any other agent functionality.
  ///
  /// Example:
  /// ```dart
  /// await SplunkOtelFlutterPlatformInterface.instance.install(
  ///   agentConfiguration: AgentConfiguration(...),
  ///   moduleConfigurations: [
  ///     CrashReportsModuleConfiguration(),
  ///     NavigationModuleConfiguration(),
  ///   ],
  /// );
  /// ```
  Future<void> install({
    required AgentConfiguration agentConfiguration,
    required List<ModuleConfiguration> moduleConfigurations,
  });

  // State

  Future<String> stateGetAppName();
  Future<String> stateGetAppVersion();
  Future<Status> stateGetStatus();
  Future<EndpointConfiguration?> stateGetEndpointConfiguration();
  Future<String> stateGetDeploymentEnvironment();
  Future<bool> stateGetIsDebugLoggingEnabled();
  Future<String?> stateGetInstrumentedProcessName();
  Future<bool> stateGetDeferredUntilForeground();

  // Preferences

  Future<EndpointConfiguration?> preferencesGetEndpointConfiguration();
  Future<void> preferencesSetEndpointConfiguration({
    required EndpointConfiguration endpointConfiguration,
  });

  // Session

  Future<String> sessionStateGetId();
  Future<double> sessionStateGetSamplingRate();

  // User

  Future<UserTrackingMode> userStateGetUserTrackingMode();
  Future<UserTrackingMode?> userPreferencesGetUserTrackingMode();
  Future<void> userPreferencesSetUserTrackingMode({
    required UserTrackingMode userTrackingMode,
  });

  // Global attributes

  Future<MutableAttributeValue?> globalAttributesGet({required String key});
  Future<MutableAttributes> globalAttributesGetAll();
  Future<void> globalAttributesRemove({required String key});
  Future<void> globalAttributesRemoveAll();
  Future<bool> globalAttributesContains({required String key});
  Future<void> globalAttributesSetString({
    required String key,
    required String value,
  });
  Future<void> globalAttributesSetInt({
    required String key,
    required int value,
  });
  Future<void> globalAttributesSetDouble({
    required String key,
    required double value,
  });
  Future<void> globalAttributesSetBool({
    required String key,
    required bool value,
  });
  Future<void> globalAttributesSetStringList({
    required String key,
    required List<String> value,
  });
  Future<void> globalAttributesSetIntList({
    required String key,
    required List<int> value,
  });
  Future<void> globalAttributesSetDoubleList({
    required String key,
    required List<double> value,
  });
  Future<void> globalAttributesSetBoolList({
    required String key,
    required List<bool> value,
  });
  Future<void> globalAttributesSetAll({required MutableAttributes attributes});

  // Custom tracking

  Future<void> customTrackingTrackCustomEvent({
    required String name,
    required MutableAttributes attributes,
  });
  Future<int> customTrackingStartWorkflow({required String workflowName});
  Future<void> customTrackingEndWorkflow({required int handle});

  // Navigation

  Future<void> navigationTrack({required String screenName});
}
