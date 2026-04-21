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

/// Splunk OpenTelemetry Flutter plugin for real user monitoring (RUM).
///
/// This library provides comprehensive mobile application monitoring for Flutter apps,
/// enabling you to track performance, crashes, network requests, user interactions,
/// and custom business events.
///
/// ## Getting Started
///
/// 1. Install the Splunk RUM agent at app startup:
///
/// ```dart
/// import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
///
/// void main() async {
///   await SplunkRum.instance.install(
///     agentConfiguration: AgentConfiguration(
///       endpoint: EndpointConfiguration.forRum(
///         realm: 'us0',
///         rumAccessToken: 'your-rum-access-token',
///       ),
///       appName: 'MyApp',
///       deploymentEnvironment: 'production',
///     ),
///     moduleConfigurations: [
///       CrashReportsModuleConfiguration(),
///       NavigationModuleConfiguration(isAutomatedTrackingEnabled: true),
///       NetworkMonitorModuleConfiguration(),
///     ],
///   );
///
///   runApp(MyApp());
/// }
/// ```
///
/// 2. Use SDK features throughout your app:
///
/// ```dart
/// // Track custom events
/// await SplunkRum.instance.customTracking.trackCustomEvent(
///   name: 'purchase_complete',
///   attributes: MutableAttributes(attributes: {
///     'amount': MutableAttributeDouble(value: 99.99),
///   }),
/// );
///
/// // Add global attributes
/// await SplunkRum.instance.globalAttributes.setString(
///   key: 'user.tier',
///   value: 'premium',
/// );
///
/// // Track workflows
/// final workflow = await SplunkRum.instance.customTracking.startWorkflow(
///   name: 'checkout_flow',
/// );
/// // ... perform workflow steps ...
/// await workflow.end();
/// ```
///
/// ## Key Features
///
/// - **Automatic instrumentation**: Crashes, ANRs, network requests, slow rendering
/// - **Manual instrumentation**: Custom events, workflows, screen navigation
/// - **Session management**: Session IDs and sampling control
/// - **Global attributes**: Enrich all telemetry with custom metadata
/// - **User tracking**: Anonymous or no-tracking modes
/// - **Cross-platform**: Supports Android and iOS
///
/// For more information, see the [Splunk RUM documentation](https://docs.splunk.com/Observability/rum/intro-to-rum.html).
library splunk_otel_flutter;

export 'package:splunk_otel_flutter_platform_interface/src/model/agent_configuration.dart';
export 'package:splunk_otel_flutter_platform_interface/src/model/status.dart';
export 'package:splunk_otel_flutter_platform_interface/src/model/module_configuration.dart';
export 'package:splunk_otel_flutter_platform_interface/src/model/mutable_attributes.dart';
export 'package:splunk_otel_flutter/src/splunk_otel_flutter.dart';
export 'package:splunk_otel_flutter/src/global_attributes.dart';
export 'package:splunk_otel_flutter/src/custom_tracking.dart'
    show WorkflowHandle;
