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
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

/// Base class for module configurations.
///
/// Modules configure optional SDK features like network monitoring,
/// crash reporting, slow rendering detection, etc.
///
/// Pass module configurations to `SplunkRum.instance.install()`.
///
/// Example:
/// ```dart
/// await SplunkRum.instance.install(
///   agentConfiguration: AgentConfiguration(...),
///   moduleConfigurations: [
///     CrashReportsModuleConfiguration(isEnabled: true),
///     SlowRenderingModuleConfiguration(isEnabled: true),
///     NetworkMonitorModuleConfiguration(isEnabled: false),
///   ],
/// );
/// ```
abstract class ModuleConfiguration {
  ModuleConfiguration();
}

/// Base class for module configurations that can be enabled or disabled.
abstract class ActivableModuleConfiguration extends ModuleConfiguration {
  /// Whether this module is enabled. Defaults to `true` for all modules.
  final bool isEnabled;

  ActivableModuleConfiguration({required this.isEnabled});
}

/// Slow/frozen frame detection configuration.
///
/// Detects UI frames that take too long to render, indicating performance issues.
class SlowRenderingModuleConfiguration extends ActivableModuleConfiguration {
  /// Polling interval for checking frame rendering performance.
  /// **Android only.** Defaults to 1 second.
  final Duration interval;

  SlowRenderingModuleConfiguration({
    super.isEnabled = true,
    this.interval = const Duration(seconds: 1),
  });
}

/// Screen navigation tracking configuration.
///
/// Enables the navigation module that emits the `app.ui.navigation` signal and
/// owns the shared `screen.name` propagated to all other telemetry. The module
/// must be enabled (`isEnabled`, the default) for any navigation tracking to
/// work — manual `SplunkRum.instance.navigation.track(...)` calls and the
/// Flutter [SplunkNavigatorObserver] both depend on it.
///
/// ## Native vs. Flutter automatic tracking
///
/// These are two independent mechanisms; do not confuse them:
///
/// - [isAutomatedTrackingEnabled] toggles **native** automatic detection only
///   (`Activity`/`Fragment` on Android, `UIViewController` on iOS). It does
///   **not** control Flutter route tracking. On a Flutter app, native detection
///   only sees the host `FlutterActivity` / `FlutterViewController` (plus any
///   genuinely embedded native screens) — never your Dart routes.
/// - To automatically track Flutter (Dart) routes, add a
///   `SplunkNavigatorObserver` to your app's `Navigator` (for example,
///   `MaterialApp.navigatorObservers`). That observer is configured on its own
///   and is independent of [isAutomatedTrackingEnabled].
///
/// Recommended Flutter setup: keep [isAutomatedTrackingEnabled] `false` (the
/// default) and install a `SplunkNavigatorObserver`.
class NavigationModuleConfiguration extends ActivableModuleConfiguration {
  /// Enables **native** automatic navigation detection (`Activity`/`Fragment`
  /// on Android, `UIViewController` on iOS).
  ///
  /// This is unrelated to Flutter route tracking: on Flutter it only observes
  /// the native host (the `FlutterActivity` / `FlutterViewController` and any
  /// embedded native screens), not Dart `Navigator` routes. For automatic
  /// Flutter route tracking, install a `SplunkNavigatorObserver` instead.
  ///
  /// Defaults to `false`.
  final bool isAutomatedTrackingEnabled;

  NavigationModuleConfiguration({
    super.isEnabled = true,
    this.isAutomatedTrackingEnabled = false,
  });
}

/// Crash reporting configuration.
///
/// Captures unhandled exceptions and crashes.
class CrashReportsModuleConfiguration extends ActivableModuleConfiguration {
  CrashReportsModuleConfiguration({super.isEnabled = true});
}

/// User interactions tracking configuration.
///
/// Tracks user taps/clicks on UI elements, creating spans with element details.
class InteractionsModuleConfiguration extends ActivableModuleConfiguration {
  InteractionsModuleConfiguration({super.isEnabled = true});
}

/// Network connectivity monitoring configuration.
///
/// Tracks network type changes (WiFi, cellular, offline, etc.).
/// Adds `network.connection.type` attribute to spans.
class NetworkMonitorModuleConfiguration extends ActivableModuleConfiguration {
  NetworkMonitorModuleConfiguration({super.isEnabled = true});
}

/// Application lifecycle events configuration.
///
/// Tracks app foreground/background transitions.
/// **Note:** This configuration can only be disabled on Android. On iOS, the configuration is ignored and lifecycle tracking behavior is not controlled by this setting.
class ApplicationLifecycleModuleConfiguration
    extends ActivableModuleConfiguration {
  ApplicationLifecycleModuleConfiguration({super.isEnabled = true});
}

// only Android

/// ANR (Application Not Responding) detection configuration.
///
/// **Android only.** Detects when the main thread is blocked.
class AnrModuleConfiguration extends ActivableModuleConfiguration {
  AnrModuleConfiguration({super.isEnabled = true});
}

/// **Android only.** HttpURLConnection instrumentation configuration.
///
/// Instruments Java's `HttpURLConnection` for network tracing.
class HttpUrlModuleConfiguration extends ActivableModuleConfiguration {
  /// HTTP request header names to capture as span attributes.
  ///
  /// Names are trimmed; empty entries, entries that are not valid RFC 7230
  /// header tokens, and case-insensitive duplicates are discarded before
  /// being forwarded to the native agent.
  ///
  /// **Security:** do not capture headers that carry credentials or session
  /// material (for example `Authorization`, `Proxy-Authorization`, `Cookie`).
  /// Their values would be persisted verbatim in telemetry and could leak
  /// secrets to the backend and anyone with access to it.
  final List<String> capturedRequestHeaders;

  /// HTTP response header names to capture as span attributes.
  ///
  /// Names are trimmed; empty entries, entries that are not valid RFC 7230
  /// header tokens, and case-insensitive duplicates are discarded before
  /// being forwarded to the native agent.
  ///
  /// **Security:** avoid capturing headers that carry session material such
  /// as `Set-Cookie` or `Set-Cookie2` to prevent leaking session identifiers
  /// into telemetry.
  final List<String> capturedResponseHeaders;

  HttpUrlModuleConfiguration({
    super.isEnabled = true,
    this.capturedRequestHeaders = const [],
    this.capturedResponseHeaders = const [],
  });
}

/// **Android only.** OkHttp3 automatic instrumentation configuration.
///
/// Automatically instruments all OkHttp3 clients for network tracing.
class OkHttp3AutoModuleConfiguration extends ActivableModuleConfiguration {
  /// HTTP request header names to capture as span attributes.
  ///
  /// Names are trimmed; empty entries, entries that are not valid RFC 7230
  /// header tokens, and case-insensitive duplicates are discarded before
  /// being forwarded to the native agent.
  ///
  /// **Security:** do not capture headers that carry credentials or session
  /// material (for example `Authorization`, `Proxy-Authorization`, `Cookie`).
  /// Their values would be persisted verbatim in telemetry and could leak
  /// secrets to the backend and anyone with access to it.
  final List<String> capturedRequestHeaders;

  /// HTTP response header names to capture as span attributes.
  ///
  /// Names are trimmed; empty entries, entries that are not valid RFC 7230
  /// header tokens, and case-insensitive duplicates are discarded before
  /// being forwarded to the native agent.
  ///
  /// **Security:** avoid capturing headers that carry session material such
  /// as `Set-Cookie` or `Set-Cookie2` to prevent leaking session identifiers
  /// into telemetry.
  final List<String> capturedResponseHeaders;

  OkHttp3AutoModuleConfiguration({
    super.isEnabled = true,
    this.capturedRequestHeaders = const [],
    this.capturedResponseHeaders = const [],
  });
}

/// Session replay module configuration.
///
/// Enables screen recording for session replay in Splunk Observability Cloud.
/// Requires the `splunk_otel_flutter_session_replay` package to be installed.
class SessionReplayModuleConfiguration extends ActivableModuleConfiguration {
  /// Sampling rate for session replay recording (0.0 to 1.0).
  ///
  /// A value of 1.0 means all sessions are recorded (100%).
  /// A value of 0.5 means half of sessions are recorded (50%).
  /// Values outside the valid range are clamped to [0.0, 1.0].
  /// Defaults to 0.2.
  final double samplingRate;

  SessionReplayModuleConfiguration({
    super.isEnabled = true,
    double samplingRate = 0.2,
  }) : samplingRate = samplingRate.clamp(0.0, 1.0) {
    if (samplingRate < 0.0 || samplingRate > 1.0) {
      debugPrint(
        'SplunkRum: samplingRate must be between 0.0 and 1.0 (inclusive). '
        'Received: $samplingRate. Clamped to ${samplingRate.clamp(0.0, 1.0)}.',
      );
    }
  }
}

// only iOS

/// **iOS only.** Network instrumentation configuration.
///
/// Instruments `URLSession` requests for distributed tracing.
class NetworkInstrumentationModuleConfiguration
    extends ActivableModuleConfiguration {
  /// Regular expression patterns for URLs to exclude from tracing.
  /// Multiple patterns are combined with OR logic.
  final List<RegularExpression> ignoreURLs;

  /// HTTP request header names to capture as span attributes.
  ///
  /// When non-empty, matching headers from outgoing requests are added to
  /// the HTTP span as `http.request.header.<lowercased-name>`. Header
  /// matching is case-insensitive. Names are trimmed; empty entries,
  /// entries that are not valid RFC 7230 header tokens, and case-insensitive
  /// duplicates are discarded before being forwarded to the native agent.
  ///
  /// **Security:** do not capture headers that carry credentials or session
  /// material (for example `Authorization`, `Proxy-Authorization`, `Cookie`).
  /// Their values would be persisted verbatim in telemetry and could leak
  /// secrets to the backend and anyone with access to it.
  final List<String> capturedRequestHeaders;

  /// HTTP response header names to capture as span attributes.
  ///
  /// When non-empty, matching headers from incoming responses are added to
  /// the HTTP span as `http.response.header.<lowercased-name>`. Header
  /// matching is case-insensitive. Names are trimmed; empty entries,
  /// entries that are not valid RFC 7230 header tokens, and case-insensitive
  /// duplicates are discarded before being forwarded to the native agent.
  ///
  /// **Security:** avoid capturing headers that carry session material such
  /// as `Set-Cookie` or `Set-Cookie2` to prevent leaking session identifiers
  /// into telemetry.
  ///
  /// Note: multi-value headers are comma-joined by the native agent. Avoid
  /// capturing headers whose values may contain commas (for example,
  /// `Set-Cookie`) because their original structure cannot be reliably
  /// reconstructed from the attribute value.
  final List<String> capturedResponseHeaders;

  NetworkInstrumentationModuleConfiguration({
    super.isEnabled = true,
    this.ignoreURLs = const [],
    this.capturedRequestHeaders = const [],
    this.capturedResponseHeaders = const [],
  });
}

/// Regular expression options for URL pattern matching.
///
/// Used with [RegularExpression] to configure regex behavior for excluding URLs
/// from network instrumentation.
enum RegexOption {
  /// Case-insensitive matching.
  caseInsensitive,

  /// Allow comments and whitespace in the pattern.
  allowCommentsAndWhitespace,

  /// Ignore metacharacters, treating them as literals.
  ignoreMetacharacters,

  /// Dot (.) matches line separators.
  dotMatchesLineSeparators,

  /// Anchors (^ and $) match at line boundaries.
  anchorsMatchLines,

  /// Use Unix line separators.
  useUnixLineSeparators,

  /// Use Unicode word boundaries.
  useUnicodeWordBoundaries,
}

/// Regular expression pattern for matching URLs.
///
/// Used with [NetworkInstrumentationModuleConfiguration] to exclude specific URLs
/// from network tracing on iOS.
class RegularExpression {
  /// The regex pattern string.
  final String pattern;

  /// Optional regex options to modify pattern behavior.
  final List<RegexOption?>? options;

  RegularExpression({required this.pattern, this.options});
}

extension RegexSpecMapper on RegularExpression {
  GeneratedRegularExpression toGeneratedRegularExpression() {
    return GeneratedRegularExpression(
      pattern: pattern,
      options: options?.map((opt) {
        switch (opt) {
          case RegexOption.caseInsensitive:
            return GeneratedRegexOption.caseInsensitive;
          case RegexOption.allowCommentsAndWhitespace:
            return GeneratedRegexOption.allowCommentsAndWhitespace;
          case RegexOption.ignoreMetacharacters:
            return GeneratedRegexOption.ignoreMetacharacters;
          case RegexOption.dotMatchesLineSeparators:
            return GeneratedRegexOption.dotMatchesLineSeparators;
          case RegexOption.anchorsMatchLines:
            return GeneratedRegexOption.anchorsMatchLines;
          case RegexOption.useUnixLineSeparators:
            return GeneratedRegexOption.useUnixLineSeparators;
          case RegexOption.useUnicodeWordBoundaries:
            return GeneratedRegexOption.useUnicodeWordBoundaries;
          default:
            return null;
        }
      }).toList(),
    );
  }
}

extension GeneratedRegexSpecMapper on GeneratedRegularExpression {
  RegularExpression toRegularExpression() {
    return RegularExpression(
      pattern: pattern,
      options: options?.map((opt) {
        switch (opt) {
          case GeneratedRegexOption.caseInsensitive:
            return RegexOption.caseInsensitive;
          case GeneratedRegexOption.allowCommentsAndWhitespace:
            return RegexOption.allowCommentsAndWhitespace;
          case GeneratedRegexOption.ignoreMetacharacters:
            return RegexOption.ignoreMetacharacters;
          case GeneratedRegexOption.dotMatchesLineSeparators:
            return RegexOption.dotMatchesLineSeparators;
          case GeneratedRegexOption.anchorsMatchLines:
            return RegexOption.anchorsMatchLines;
          case GeneratedRegexOption.useUnixLineSeparators:
            return RegexOption.useUnixLineSeparators;
          case GeneratedRegexOption.useUnicodeWordBoundaries:
            return RegexOption.useUnicodeWordBoundaries;
          default:
            return null;
        }
      }).toList(),
    );
  }
}

extension RegularExpressionListMapper on List<RegularExpression> {
  List<GeneratedRegularExpression> toGeneratedList() =>
      map((e) => e.toGeneratedRegularExpression()).toList();
}

extension GeneratedRegularExpressionListMapper
    on List<GeneratedRegularExpression> {
  List<RegularExpression> toRegularExpressionList() =>
      map((e) => e.toRegularExpression()).toList();
}
