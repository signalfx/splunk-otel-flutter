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

/// Handle to an active workflow span.
///
/// Returned by [CustomTracking.startWorkflow] to track a workflow's duration.
/// Call [end] to complete the workflow and record its duration.
class WorkflowHandle {
  final int _handle;
  final SplunkOtelFlutterPlatformImplementation _delegate;

  WorkflowHandle._(this._handle, this._delegate);

  /// Ends the workflow span.
  ///
  /// Records the workflow duration from when [CustomTracking.startWorkflow] was called
  /// to this call. The duration is measured automatically.
  Future<void> end() async {
    await _delegate.customTrackingEndWorkflow(handle: _handle);
  }
}

/// Custom event and workflow tracking.
///
/// Use to capture business events and measure user workflows.
///
/// Example custom event:
/// ```dart
/// await SplunkRum.instance.customTracking.trackCustomEvent(
///   name: 'checkout_complete',
///   attributes: MutableAttributes({
///     'order.total': 99.99,
///     'order.items': 3,
///   }),
/// );
/// ```
///
/// Example workflow tracking:
/// ```dart
/// // Start the workflow and get a handle
/// final workflow = await SplunkRum.instance.customTracking.startWorkflow(
///   name: 'user_login',
/// );
///
/// // ... perform workflow operations ...
///
/// // End the workflow to record its duration
/// await workflow.end();
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
  /// await SplunkRum.instance.customTracking.trackCustomEvent(
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

  /// Starts a workflow span for duration measurement.
  ///
  /// Returns a handle that can be used to end the workflow later. The span duration
  /// measures the time between this call and when `end()` is called on the returned handle.
  ///
  /// [name] - Workflow name (becomes span name and `workflow.name` attribute).
  ///
  /// Returns a [WorkflowHandle] that can be used to end the workflow.
  ///
  /// Example:
  /// ```dart
  /// // Start the workflow and get a handle
  /// final workflow = await SplunkRum.instance.customTracking.startWorkflow(
  ///   name: 'user_login',
  /// );
  ///
  /// // ... perform workflow operations ...
  ///
  /// // End the workflow to record its duration
  /// await workflow.end();
  /// ```
  Future<WorkflowHandle> startWorkflow({required String name}) async {
    final handle = await _delegate.customTrackingStartWorkflow(
      workflowName: name,
    );
    return WorkflowHandle._(handle, _delegate);
  }
}
