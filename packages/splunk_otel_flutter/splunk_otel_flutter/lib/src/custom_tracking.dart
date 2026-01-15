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

/// Custom event and workflow tracking.
///
/// Use to capture business events and measure user workflows.
///
/// Example:
/// ```dart
/// await SplunkOtelFlutter.instance.customTracking.trackCustomEvent(
///   name: 'checkout_complete',
///   attributes: MutableAttributes({
///     'order.total': 99.99,
///     'order.items': 3,
///   }),
/// );
/// ```
class CustomTracking {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  /// Tracks a custom event.
  ///
  /// Creates a zero-length span with the event name and attributes.
  ///
  /// [name] - Event name (becomes span name).
  /// [attributes] - Optional attributes to attach to the event.
  ///
  /// Example:
  /// ```dart
  /// await SplunkOtelFlutter.instance.customTracking.trackCustomEvent(
  ///   name: 'user_signup',
  ///   attributes: MutableAttributes({
  ///     'user.email': 'user@example.com',
  ///     'user.plan': 'premium',
  ///   }),
  /// );
  /// ```
  Future<void> trackCustomEvent({
    required String name,
    MutableAttributes attributes = const MutableAttributes(),
  }) async =>
      await _delegate.customTrackingTrackCustomEvent(
        name: name,
        attributes: attributes,
      );

  /// Tracks a workflow span for duration measurement.
  ///
  /// Call this method twice for each workflow: the first call starts the workflow,
  /// and the second call ends it, measuring the duration between them. This pattern
  /// can be repeated infinitely, always pairing up start and end calls.
  ///
  /// [workflowName] - Workflow name (becomes span name and `workflow.name` attribute).
  ///
  /// Example:
  /// ```dart
  /// // Start the workflow
  /// await SplunkOtelFlutter.instance.customTracking.trackWorkflow(
  ///   workflowName: 'user_login',
  /// );
  ///
  /// // ... workflow executes ...
  ///
  /// // End the workflow (measures duration)
  /// await SplunkOtelFlutter.instance.customTracking.trackWorkflow(
  ///   workflowName: 'user_login',
  /// );
  /// ```
  Future<void> trackWorkflow({
    required String workflowName,
  }) async =>
      await _delegate.customTrackingTrackWorkflow(
        workflowName: workflowName,
      );
}
