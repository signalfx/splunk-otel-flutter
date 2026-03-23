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

import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

/// Agent runtime state.
///
/// Reflects current configuration and status.
class State {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  /// Gets configured application name.
  ///
  /// Returns the app name specified during SDK installation.
  Future<String> getAppName() async => await _delegate.stateGetAppName();

  /// Gets configured application version.
  ///
  /// Returns the app version specified during SDK installation.
  Future<String> getAppVersion() async => await _delegate.stateGetAppVersion();

  /// Gets current agent status.
  ///
  /// Returns the agent's runtime status indicating whether it's running
  /// and if not, the reason why.
  Future<Status> getStatus() async => await _delegate.stateGetStatus();

  /// Gets configured endpoint.
  ///
  /// Returns the endpoint configuration (realm, rumAccessToken, etc.)
  /// specified during SDK installation, or `null` if not yet set.
  Future<EndpointConfiguration?> getEndpointConfiguration() async => await _delegate.stateGetEndpointConfiguration();

  /// Gets configured deployment environment.
  ///
  /// Returns the deployment environment (e.g., 'production', 'staging')
  /// specified during SDK installation.
  Future<String> getDeploymentEnvironment() async => await _delegate.stateGetDeploymentEnvironment();

  /// Gets whether debug logging is enabled.
  ///
  /// Returns `true` if debug logging was enabled during SDK installation.
  Future<bool> getIsDebugLoggingEnabled() async => await _delegate.stateGetIsDebugLoggingEnabled();

  /// Gets instrumented process name.
  ///
  /// **Android only.** Returns the name of the instrumented process,
  /// or `null` if not available or on iOS.
  Future<String?> getInstrumentedProcessName() async => await _delegate.stateGetInstrumentedProcessName();

  /// Gets whether initialization was deferred.
  ///
  /// **Android only.** Returns `true` if SDK initialization was deferred
  /// until the app came to the foreground.
  Future<bool> getDeferredUntilForeground() async => await _delegate.stateGetDeferredUntilForeground();
}

