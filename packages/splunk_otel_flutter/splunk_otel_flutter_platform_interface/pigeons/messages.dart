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

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/pigeon/messages.pigeon.dart',
    dartPackageName: 'splunk_otel_flutter_platform_interface',
    kotlinOut:
        '../splunk_otel_flutter/android/src/main/kotlin/com/splunk/rum/flutter/GeneratedAndroidSplunkOtelFlutter.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.splunk.rum.flutter',
    ),
    swiftOut:
        '../splunk_otel_flutter/ios/splunk_otel_flutter/Sources/splunk_otel_flutter/SplunkOtelFlutterMessages.g.swift',
  ),
)
@HostApi()
abstract class SplunkOtelFlutterHostApi {
  @async
  void install(
      {required GeneratedAgentConfiguration agentConfiguration,
      // Core configurations
      required GeneratedNavigationModuleConfiguration?
          navigationModuleConfiguration,
      required GeneratedSlowRenderingModuleConfiguration?
          slowRenderingModuleConfiguration,
      required GeneratedCrashReportsModuleConfiguration?
          crashReportsModuleConfiguration,
      required GeneratedInteractionsModuleConfiguration?
          interactionsModuleConfiguration,
      required GeneratedNetworkMonitorModuleConfiguration?
          networkMonitorModuleConfiguration,
      required GeneratedApplicationLifecycleModuleConfiguration?
          applicationLifecycleModuleConfiguration,

      // Android-only configurations
      required GeneratedAnrModuleConfiguration? anrModuleConfiguration,
      required GeneratedHttpUrlModuleConfiguration? httpUrlModuleConfiguration,
      required GeneratedOkHttp3AutoModuleConfiguration?
          okHttp3AutoModuleConfiguration,

      // iOS-only configurations
      required GeneratedNetworkInstrumentationModuleConfiguration?
          networkInstrumentationModuleConfiguration});

  // State

  @async
  String stateGetAppName();

  @async
  String stateGetAppVersion();

  @async
  GeneratedStatus stateGetStatus();

  @async
  GeneratedEndpointConfiguration? stateGetEndpointConfiguration();

  @async
  String stateGetDeploymentEnvironment();

  @async
  bool stateGetIsDebugLoggingEnabled();

  @async
  String? stateGetInstrumentedProcessName();

  @async
  bool stateGetDeferredUntilForeground();

  @async
  void stateSetEndpointConfiguration({
    required GeneratedEndpointConfiguration endpointConfiguration,
  });

  // Preferences

  @async
  GeneratedEndpointConfiguration? preferencesGetEndpointConfiguration();

  // Session

  @async
  String sessionStateGetId();

  @async
  double sessionStateGetSamplingRate();

  // User

  @async
  GeneratedUserTrackingMode userStateGetUserTrackingMode();

  @async
  GeneratedUserTrackingMode? userPreferencesGetUserTrackingMode();

  @async
  void userPreferencesSetUserTrackingMode({
    required GeneratedUserTrackingMode trackingMode,
  });

  // Global attributes

  @async
  Object? globalAttributesGet({required String key});

  @async
  GeneratedMutableAttributes? globalAttributesGetAll();

  @async
  void globalAttributesRemove({required String key});

  @async
  void globalAttributesRemoveAll();

  @async
  bool globalAttributesContains({required String key});

  @async
  void globalAttributesSetString({required String key, required String value});

  @async
  void globalAttributesSetInt({required String key, required int value});

  @async
  void globalAttributesSetDouble({required String key, required double value});

  @async
  void globalAttributesSetBool({required String key, required bool value});

  @async
  void globalAttributesSetStringList(
      {required String key, required List<String> value});

  @async
  void globalAttributesSetIntList(
      {required String key, required List<int> value});

  @async
  void globalAttributesSetDoubleList(
      {required String key, required List<double> value});

  @async
  void globalAttributesSetBoolList(
      {required String key, required List<bool> value});

  @async
  void globalAttributesSetAll({required GeneratedMutableAttributes value});

  // Custom tracking

  @async
  void customTrackingTrackCustomEvent({required String name, required GeneratedMutableAttributes attributes});

  @async
  int customTrackingStartWorkflow({required String workflowName});

  @async
  void customTrackingEndWorkflow({required int handle});

  // Navigation

  @async
  void navigationTrack({required String screenName});
}

// Configurations

class GeneratedSlowRenderingModuleConfiguration {
  final bool isEnabled;
  final int intervalMillis;

  GeneratedSlowRenderingModuleConfiguration({
    required this.isEnabled,
    required this.intervalMillis,
  });
}

class GeneratedNavigationModuleConfiguration {
  final bool isEnabled;
  final bool isAutomatedTrackingEnabled;

  GeneratedNavigationModuleConfiguration({
    required this.isEnabled,
    required this.isAutomatedTrackingEnabled,
  });
}

class GeneratedCrashReportsModuleConfiguration {
  final bool isEnabled;

  GeneratedCrashReportsModuleConfiguration({
    required this.isEnabled,
  });
}

class GeneratedInteractionsModuleConfiguration {
  final bool isEnabled;

  GeneratedInteractionsModuleConfiguration({
    required this.isEnabled,
  });
}

class GeneratedNetworkMonitorModuleConfiguration {
  final bool isEnabled;

  GeneratedNetworkMonitorModuleConfiguration({
    required this.isEnabled,
  });
}

class GeneratedApplicationLifecycleModuleConfiguration {
  final bool isEnabled;

  GeneratedApplicationLifecycleModuleConfiguration({
    required this.isEnabled,
  });
}

// ANDROID ONLY

class GeneratedAnrModuleConfiguration {
  final bool isEnabled;

  GeneratedAnrModuleConfiguration({
    required this.isEnabled,
  });
}

class GeneratedHttpUrlModuleConfiguration {
  final bool isEnabled;
  final List<String> capturedRequestHeaders;
  final List<String> capturedResponseHeaders;

  GeneratedHttpUrlModuleConfiguration({
    required this.isEnabled,
    required this.capturedRequestHeaders,
    required this.capturedResponseHeaders,
  });
}

class GeneratedOkHttp3AutoModuleConfiguration {
  final bool isEnabled;
  final List<String> capturedRequestHeaders;
  final List<String> capturedResponseHeaders;

  GeneratedOkHttp3AutoModuleConfiguration({
    required this.isEnabled,
    required this.capturedRequestHeaders,
    required this.capturedResponseHeaders,
  });
}

// iOS ONLY
class GeneratedNetworkInstrumentationModuleConfiguration {
  final bool isEnabled;
  final List<GeneratedRegularExpression> ignoreURLs;

  GeneratedNetworkInstrumentationModuleConfiguration({
    required this.isEnabled,
    required this.ignoreURLs,
  });
}

enum GeneratedRegexOption {
  caseInsensitive,
  allowCommentsAndWhitespace,
  ignoreMetacharacters,
  dotMatchesLineSeparators,
  anchorsMatchLines,
  useUnixLineSeparators,
  useUnicodeWordBoundaries,
}

class GeneratedRegularExpression {
  final String pattern;
  final List<GeneratedRegexOption?>? options;

  GeneratedRegularExpression({
    required this.pattern,
    required this.options,
  });
}

class GeneratedAgentConfiguration {
  // Required properties (common to iOS and Android).
  final String appName;
  final String deploymentEnvironment;

  // Optional properties (common to iOS and Android).
  final GeneratedEndpointConfiguration? endpoint;

  // On iOS, this typically defaults to CFBundleShortVersionString.
  final String? appVersion;

  // Enables or disables debug logging. Defaults to false.
  final bool? enableDebugLogging;

  // Global attributes sent with all signals.
  // iOS: MutableAttributes; Android: Attributes. Represented here as a map.
  final GeneratedMutableAttributes? globalAttributes;

  // User and session configuration (common to iOS and Android).
  final GeneratedUserConfiguration? user;
  final GeneratedSessionConfiguration? session;

  // Android-only extras.
  final String? instrumentedProcessName; // Android-only.
  final bool? deferredUntilForeground; // Android-only.

  GeneratedAgentConfiguration({
    required this.appName,
    required this.deploymentEnvironment,
    this.endpoint,
    this.appVersion,
    this.enableDebugLogging,
    this.globalAttributes,
    this.user,
    this.session,
    this.instrumentedProcessName, // Android-only.
    this.deferredUntilForeground, // Android-only.
  });
}

class GeneratedEndpointConfiguration {
  final String? traceEndpoint;
  final String? sessionReplayEndpoint;
  final String? realm;
  final String? rumAccessToken;

  GeneratedEndpointConfiguration({
    this.traceEndpoint,
    this.sessionReplayEndpoint,
    this.realm,
    this.rumAccessToken,
  });
}

class GeneratedUserConfiguration {
  final GeneratedUserTrackingMode trackingMode;

  GeneratedUserConfiguration({required this.trackingMode});
}

enum GeneratedUserTrackingMode {
  noTracking,
  anonymousTracking,
}

class GeneratedSessionConfiguration {
  final double samplingRate;

  GeneratedSessionConfiguration({required this.samplingRate});
}

// Session replay

enum GeneratedSessionReplayStatus {
  isRecording,
  notStarted,
  stopped,
  belowMinSdkVersion,
  storageLimitReached,
  internalError,
}

enum GeneratedRenderingMode { native, wireframeOnly }

class GeneratedRecordingMaskList {
  final List<GeneratedRecordingMaskElement>? recordingMaskList;

  GeneratedRecordingMaskList({
    required this.recordingMaskList,
  });
}

class GeneratedRecordingMaskElement {
  final GeneratedRect rect;
  final GeneratedRecordingMaskType type;

  GeneratedRecordingMaskElement({
    required this.rect,
    required this.type,
  });
}

class GeneratedRect {
  final double left;
  final double top;
  final double width;
  final double height;

  GeneratedRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

enum GeneratedRecordingMaskType {
  erasing,
  covering,
}

// Status

enum GeneratedStatus {
  running,
  notInstalled,
  subProcess,
  sampledOut,
  unsupportedPlatform,
  unsupportedOsVersion,
}

// Global attributes

class GeneratedMutableAttributes {
  final Map<String, Object?> attributes;

  GeneratedMutableAttributes({required this.attributes});
}

class GeneratedMutableAttributeInt {
  final int value;

  GeneratedMutableAttributeInt({required this.value});
}

class GeneratedMutableAttributeDouble {
  final double value;

  GeneratedMutableAttributeDouble({required this.value});
}

class GeneratedMutableAttributeString {
  final String value;

  GeneratedMutableAttributeString({required this.value});
}

class GeneratedMutableAttributeBool {
  final bool value;

  GeneratedMutableAttributeBool({required this.value});
}

class GeneratedMutableAttributeListInt {
  final List<int> value;

  GeneratedMutableAttributeListInt({required this.value});
}

class GeneratedMutableAttributeListDouble {
  final List<double> value;

  GeneratedMutableAttributeListDouble({required this.value});
}

class GeneratedMutableAttributeListString {
  final List<String> value;

  GeneratedMutableAttributeListString({required this.value});
}

class GeneratedMutableAttributeListBool {
  final List<bool> value;

  GeneratedMutableAttributeListBool({required this.value});
}
