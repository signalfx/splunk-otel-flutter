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

import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

abstract class ModuleConfiguration {
  ModuleConfiguration();
}

abstract class ActivableModuleConfiguration extends ModuleConfiguration{
  final bool isEnabled;

  ActivableModuleConfiguration({required this.isEnabled});
}


class SlowRenderingModuleConfiguration extends ActivableModuleConfiguration {
  final Duration interval;

  SlowRenderingModuleConfiguration({
    super.isEnabled = true,
    this.interval = const Duration(seconds: 1),
  });
}

class NavigationModuleConfiguration extends ActivableModuleConfiguration {
  final bool isAutomatedTrackingEnabled;

  NavigationModuleConfiguration({
    super.isEnabled = true,
    this.isAutomatedTrackingEnabled = false,
  });
}

class CrashReportsModuleConfiguration extends ActivableModuleConfiguration {
  CrashReportsModuleConfiguration({
    super.isEnabled = true,
  });
}

class InteractionsModuleConfiguration extends ActivableModuleConfiguration {
  InteractionsModuleConfiguration({
    super.isEnabled = true,
  });
}

class NetworkMonitorModuleConfiguration extends ActivableModuleConfiguration {
  NetworkMonitorModuleConfiguration({
    super.isEnabled = true,
  });
}

// only Android

class AnrModuleConfiguration extends ActivableModuleConfiguration {
  AnrModuleConfiguration({
    super.isEnabled = true,
  });
}

class HttpUrlModuleConfiguration extends ActivableModuleConfiguration {
  final List<String> capturedRequestHeaders;
  final List<String> capturedResponseHeaders;

  HttpUrlModuleConfiguration({
    super.isEnabled = true,
    this.capturedRequestHeaders = const [],
    this.capturedResponseHeaders = const [],
  });
}

class OkHttp3AutoModuleConfiguration extends ActivableModuleConfiguration {
  final List<String> capturedRequestHeaders;
  final List<String> capturedResponseHeaders;

  OkHttp3AutoModuleConfiguration({
    super.isEnabled = true,
    this.capturedRequestHeaders = const [],
    this.capturedResponseHeaders = const [],
  });
}

// only iOS
class NetworkInstrumentationModuleConfiguration extends ActivableModuleConfiguration {
  final List<RegularExpression> ignoreURLs;
  NetworkInstrumentationModuleConfiguration({
    super.isEnabled = true,
    this.ignoreURLs = const [],
  });
}

enum RegexOption {
  caseInsensitive,
  allowCommentsAndWhitespace,
  ignoreMetacharacters,
  dotMatchesLineSeparators,
  anchorsMatchLines,
  useUnixLineSeparators,
  useUnicodeWordBoundaries,
}

class RegularExpression {
  final String pattern;
  final List<RegexOption?>? options;

  RegularExpression({
    required this.pattern,
    this.options,
  });
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