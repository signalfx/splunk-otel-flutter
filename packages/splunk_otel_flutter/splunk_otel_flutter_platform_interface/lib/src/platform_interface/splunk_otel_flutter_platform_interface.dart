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
import 'package:splunk_otel_flutter_platform_interface/src/implementation/splunk_otel_flutter_platform_implementation.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/agent_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/module_configuration.dart';

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

  Future<void> sessionReplayStart();

  Future<String> getSessionId();
 }
