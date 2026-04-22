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

/// Example demonstrating the Splunk OpenTelemetry platform interface API.
///
/// This example shows how to configure the agent. Note that this is a platform
/// interface package - actual functionality requires platform implementations.
void main() {
  // Example 1: Create agent configuration with RUM endpoint
  final agentConfig = AgentConfiguration(
    endpoint: EndpointConfiguration.forRum(
      realm: 'us0',
      rumAccessToken: 'your-rum-access-token',
    ),
    appName: 'ExampleApp',
    deploymentEnvironment: 'production',
    appVersion: '1.0.0',
    enableDebugLogging: true,
    globalAttributes: MutableAttributes(
      attributes: {
        'app.type': MutableAttributeString(value: 'mobile'),
        'custom.id': MutableAttributeInt(value: 12345),
      },
    ),
    user: const UserConfiguration(
      trackingMode: UserTrackingMode.anonymousTracking,
    ),
    session: SessionConfiguration(samplingRate: 1.0),
  );

  // Example 2: Create module configurations
  final moduleConfigs = [
    CrashReportsModuleConfiguration(isEnabled: true),
    NavigationModuleConfiguration(
      isEnabled: true,
      isAutomatedTrackingEnabled: true,
    ),
    SlowRenderingModuleConfiguration(
      isEnabled: true,
      interval: const Duration(seconds: 1),
    ),
    InteractionsModuleConfiguration(isEnabled: true),
    NetworkMonitorModuleConfiguration(isEnabled: true),
  ];

  // Example 3: Create custom endpoint configuration
  final customEndpointConfig = EndpointConfiguration.forTraces(
    traceEndpoint: Uri.parse('https://custom-endpoint.example.com/v1/traces'),
  );

  // Example 4: Create mutable attributes for custom events
  final eventAttributes = MutableAttributes(
    attributes: {
      'button.id': MutableAttributeString(value: 'submit_button'),
      'screen': MutableAttributeString(value: 'home'),
      'count': MutableAttributeInt(value: 1),
      'enabled': MutableAttributeBool(value: true),
    },
  );

  // Display configuration summary
  // ignore: avoid_print
  print('Agent Configuration Example:');
  // ignore: avoid_print
  print('  App Name: ${agentConfig.appName}');
  // ignore: avoid_print
  print('  Environment: ${agentConfig.deploymentEnvironment}');
  // ignore: avoid_print
  print('  Module Count: ${moduleConfigs.length}');
  // ignore: avoid_print
  print('  Custom Endpoint: ${customEndpointConfig.traceEndpoint}');
  // ignore: avoid_print
  print('  Event Attributes: ${eventAttributes.attributes.length}');
  // ignore: avoid_print
  print('\nExample completed successfully!');
  // ignore: avoid_print
  print('Note: Use splunk_otel_flutter package for actual implementation.');
}
