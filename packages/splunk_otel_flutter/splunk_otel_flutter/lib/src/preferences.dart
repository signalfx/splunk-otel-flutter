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

import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

/// Agent preferences for overriding configuration after installation.
///
/// Stores persistent configuration preferences that can override
/// the initial agent configuration.
class AgentPreferences {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  /// Gets the saved endpoint configuration preference.
  ///
  /// Returns the endpoint configuration stored in preferences,
  /// or `null` if no preference has been set.
  Future<EndpointConfiguration?> getEndpointConfiguration() async =>
      await _delegate.preferencesGetEndpointConfiguration();

  /// Sets the endpoint configuration.
  ///
  /// Use this to provide credentials when [AgentConfiguration] was created
  /// without an [EndpointConfiguration], or to update credentials at runtime.
  Future<void> setEndpointConfiguration({
    required EndpointConfiguration endpointConfiguration,
  }) async =>
      await _delegate.preferencesSetEndpointConfiguration(
        endpointConfiguration: endpointConfiguration,
      );
}

