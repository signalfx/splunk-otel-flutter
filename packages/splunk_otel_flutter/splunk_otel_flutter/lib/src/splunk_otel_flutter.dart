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
import 'package:splunk_otel_flutter/src/session.dart';
import 'package:splunk_otel_flutter/src/state.dart';
import 'package:splunk_otel_flutter/src/user.dart';
import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

/// Splunk RUM SDK entry point.
///
/// Use `SplunkRum.instance.install()` to initialize the SDK, then access features
/// via `SplunkRum.instance`.
///
/// Example:
/// ```dart
/// await SplunkRum.instance.install(
///   agentConfiguration: AgentConfiguration(
///     endpointConfiguration: EndpointConfiguration(realm: 'us0', rumAccessToken: 'YOUR_TOKEN'),
///     appName: 'MyApp',
///     deploymentEnvironment: 'production',
///   ),
///   moduleConfigurations: [],
/// );
///
/// // Access SDK features
/// await SplunkRum.instance.globalAttributes.setString(
///   key: 'user.tier',
///   value: 'premium',
/// );
/// ```
class SplunkRum {
  static final SplunkRum _instance = SplunkRum._internal();

  SplunkRum._internal();

  /// SDK singleton instance.
  ///
  /// Access after calling `install()`.
  static SplunkRum get instance => _instance;

  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  /// Session management.
  ///
  /// Provides access to session ID and sampling rate.
  final session = Session();

  /// Current agent runtime state.
  ///
  /// Reflects status, configuration, and endpoint settings.
  final state = State();

  /// User tracking management.
  ///
  /// Controls user identification mode.
  final user = User();

  /// Global attributes sent with all signals.
  ///
  /// Thread-safe mutable collection for enriching telemetry data.
  final globalAttributes = GlobalAttributes();

  /// Custom event and workflow tracking.
  ///
  /// Track business events and measure workflow durations.
  final customTracking = CustomTracking();

  /// Navigation tracking.
  ///
  /// Manually track screen navigation events.
  final navigation = Navigation();

  /// Installs the Splunk RUM SDK.
  ///
  /// Call once at app startup before accessing other SDK features.
  ///
  /// [agentConfiguration] - Agent configuration.
  /// [moduleConfigurations] - Optional module configurations for features.
  ///
  /// Example:
  /// ```dart
  /// await SplunkRum.instance.install(
  ///   agentConfiguration: AgentConfiguration(
  ///     endpointConfiguration: EndpointConfiguration(realm: 'us0', rumAccessToken: 'YOUR_TOKEN'),
  ///     appName: 'MyApp',
  ///     deploymentEnvironment: 'production',
  ///   ),
  ///   moduleConfigurations: [
  ///     SlowRenderingModuleConfiguration(enabled: true, pollingIntervalMs: 1000),
  ///   ],
  /// );
  /// ```
  Future<void> install({
    required AgentConfiguration agentConfiguration,
    List<ModuleConfiguration> moduleConfigurations = const [],
  }) async {
    await _delegate.install(
      agentConfiguration: agentConfiguration,
      moduleConfigurations: moduleConfigurations,
    );
  }
}
