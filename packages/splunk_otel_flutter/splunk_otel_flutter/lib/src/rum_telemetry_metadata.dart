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
import 'package:flutter/services.dart';
import 'package:splunk_otel_flutter/src/rum_sdk_version.dart';
import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

const String _splunkAppFrameworkFlutterVersionKey =
    'splunk.app.framework.flutter.version';

const String _rumSdkFlutterVersionKey = 'rum.sdk.flutter.version';

/// Enriches [agentConfiguration] with Splunk RUM telemetry metadata attributes.
///
/// Merges `splunk.app.framework.flutter.version` and `rum.sdk.flutter.version`
/// into the configuration's global attributes. SDK-managed keys always take
/// precedence over user-supplied values to guarantee correct telemetry.
///
/// The framework version is obtained from [FlutterVersion.version], a
/// compile-time constant injected by the Flutter toolchain. Falls back to
/// `'unknown'` when the define is absent (e.g. custom embedders).
///
/// [flutterFrameworkVersion] allows overriding the framework version for
/// testing purposes.
AgentConfiguration applyRumTelemetryMetadata(
  AgentConfiguration agentConfiguration, {
  String? flutterFrameworkVersion,
}) {
  final frameworkVersion =
      flutterFrameworkVersion ?? FlutterVersion.version ?? 'unknown';

  final existingAttributes =
      agentConfiguration.globalAttributes?.attributes ?? {};

  final mergedAttributes = <String, MutableAttributeValue>{
    ...existingAttributes,
    _splunkAppFrameworkFlutterVersionKey:
        MutableAttributeString(value: frameworkVersion),
    _rumSdkFlutterVersionKey:
        MutableAttributeString(value: rumSdkFlutterVersion),
  };

  return AgentConfiguration(
    endpoint: agentConfiguration.endpoint,
    appName: agentConfiguration.appName,
    deploymentEnvironment: agentConfiguration.deploymentEnvironment,
    appVersion: agentConfiguration.appVersion,
    enableDebugLogging: agentConfiguration.enableDebugLogging,
    globalAttributes: MutableAttributes(attributes: mergedAttributes),
    user: agentConfiguration.user,
    session: agentConfiguration.session,
    instrumentedProcessName: agentConfiguration.instrumentedProcessName,
    deferredUntilForeground: agentConfiguration.deferredUntilForeground,
  );
}

/// Exposed for unit testing.
///
/// Returns the result of [applyRumTelemetryMetadata] so tests can verify
/// the metadata enrichment without calling through Pigeon.
@visibleForTesting
AgentConfiguration mergeRumTelemetryMetadataForTesting(
  AgentConfiguration agentConfiguration, {
  String? flutterFrameworkVersion,
}) {
  return applyRumTelemetryMetadata(
    agentConfiguration,
    flutterFrameworkVersion: flutterFrameworkVersion,
  );
}
