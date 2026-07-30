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

import 'package:flutter/foundation.dart';
import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

/// The origin of a manually reported error.
///
/// The value is recorded verbatim as the `error.source` attribute on the span.
/// [ErrorSource.custom] is the expected value for manual reporting. The other
/// values denote automatic capture sources that are not yet wired up.
enum ErrorSource {
  /// An error reported explicitly by the application (the default).
  custom,

  /// An error captured from a source-level handler.
  source,

  /// An error captured from console output.
  console,

  /// An error captured from network instrumentation.
  network,
}

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
  }) async => await _delegate.customTrackingTrackCustomEvent(
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

  /// Reports a caught error or exception as a RUM error span.
  ///
  /// Captures the error at the call site and emits it natively as a
  /// `component=error` span with the supplied stacktrace preserved verbatim as
  /// `exception.stacktrace`. This is intended for handled errors, e.g. inside a
  /// `catch` block.
  ///
  /// [error] - The caught error. Any Dart object (including a `String`) is
  /// accepted. `exception.type` is derived from the runtime type (or `String`)
  /// and `exception.message` from `toString()`.
  /// [stackTrace] - The stacktrace to report. Defaults to [StackTrace.current].
  /// Pass the stacktrace from `catch (e, st)` to preserve the original throw
  /// site.
  /// [attributes] - Optional attributes to attach to the error span.
  /// [source] - The origin of the error. Defaults to [ErrorSource.custom].
  /// [handled] - Whether the error was handled (non-fatal). Defaults to `true`.
  /// Reported as `exception.escaped` (the inverse) on the span.
  ///
  /// This method never throws and always completes: if reporting itself fails
  /// (for example, the bridge is unavailable), the failure is logged and
  /// swallowed so it stays `await`-safe inside error handlers.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, st) {
  ///   await SplunkRum.instance.customTracking.trackError(e, stackTrace: st);
  /// }
  /// ```
  Future<void> trackError(
    Object error, {
    StackTrace? stackTrace,
    MutableAttributes attributes = const MutableAttributes(),
    ErrorSource source = ErrorSource.custom,
    bool handled = true,
  }) async {
    try {
      final type = error is String ? 'String' : error.runtimeType.toString();
      final resolvedStackTrace = (stackTrace ?? StackTrace.current).toString();

      await _delegate.customTrackingTrackError(
        type: type,
        message: error.toString(),
        stacktrace: resolvedStackTrace,
        attributes: attributes,
        source: source.name,
        handled: handled,
      );
    } catch (e) {
      debugPrint('SplunkRum: trackError reporting failed ($e).');
    }
  }
}
