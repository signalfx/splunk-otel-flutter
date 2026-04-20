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

/// Platform interface for Splunk OpenTelemetry Flutter instrumentation.
///
/// This library provides the platform interface layer for the Splunk OpenTelemetry
/// Flutter plugin, enabling real user monitoring (RUM), distributed tracing,
/// and application analytics across Android and iOS platforms.
///
/// Key features:
/// - Agent configuration and lifecycle management
/// - Module-based instrumentation (network, crashes, navigation, etc.)
/// - Global attributes and custom tracking
/// - Session and user tracking
library splunk_otel_flutter_platform_interface;

export 'package:splunk_otel_flutter_platform_interface/src/model/module_configuration.dart';
export 'package:splunk_otel_flutter_platform_interface/src/implementation/splunk_otel_flutter_platform_implementation.dart';
export 'package:splunk_otel_flutter_platform_interface/src/model/agent_configuration.dart'
    hide
        GeneratedEndpointConfigurationExtension,
        EndpointConfigurationExtension;
export 'package:splunk_otel_flutter_platform_interface/src/model/session_replay.dart';
export 'package:splunk_otel_flutter_platform_interface/src/model/status.dart';
export 'package:splunk_otel_flutter_platform_interface/src/model/mutable_attributes.dart'
    hide
        MutableAttributesConverter,
        GeneratedMutableAttributesConverter,
        DynamicToMutableAttributeValueConverter;
