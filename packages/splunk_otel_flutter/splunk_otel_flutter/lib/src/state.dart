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

class State {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<String> getAppName() async => await _delegate.stateGetAppName();

  Future<String> getAppVersion() async => await _delegate.stateGetAppVersion();

  Future<Status> getStatus() async => await _delegate.stateGetStatus();

  Future<EndpointConfiguration> getEndpointConfiguration() async => await _delegate.stateGetEndpointConfiguration();

  Future<String> getDeploymentEnvironment() async => await _delegate.stateGetDeploymentEnvironment();

  Future<bool> getIsDebugLoggingEnabled() async => await _delegate.stateGetIsDebugLoggingEnabled();

  Future<String?> getInstrumentedProcessName() async => await _delegate.stateGetInstrumentedProcessName();

  Future<bool> getDeferredUntilForeground() async => await _delegate.stateGetDeferredUntilForeground();
}

