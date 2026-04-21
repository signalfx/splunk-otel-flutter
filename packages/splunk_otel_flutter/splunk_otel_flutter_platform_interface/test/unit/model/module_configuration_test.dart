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

import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/module_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

void main() {
  group('SlowRenderingModuleConfiguration', () {
    test('should create with default values', () {
      final config = SlowRenderingModuleConfiguration();

      expect(config.isEnabled, true);
      expect(config.interval, const Duration(seconds: 1));
    });

    test('should create with custom values', () {
      final config = SlowRenderingModuleConfiguration(
        isEnabled: false,
        interval: const Duration(milliseconds: 500),
      );

      expect(config.isEnabled, false);
      expect(config.interval, const Duration(milliseconds: 500));
    });

    test('should handle zero duration', () {
      final config = SlowRenderingModuleConfiguration(interval: Duration.zero);

      expect(config.interval, Duration.zero);
    });

    test('should handle large duration', () {
      final config = SlowRenderingModuleConfiguration(
        interval: const Duration(minutes: 5),
      );

      expect(config.interval, const Duration(minutes: 5));
    });
  });

  group('NavigationModuleConfiguration', () {
    test('should create with default values', () {
      final config = NavigationModuleConfiguration();

      expect(config.isEnabled, true);
      expect(config.isAutomatedTrackingEnabled, false);
    });

    test('should create with custom values', () {
      final config = NavigationModuleConfiguration(
        isEnabled: false,
        isAutomatedTrackingEnabled: true,
      );

      expect(config.isEnabled, false);
      expect(config.isAutomatedTrackingEnabled, true);
    });

    test('should handle enabled with automated tracking', () {
      final config = NavigationModuleConfiguration(
        isEnabled: true,
        isAutomatedTrackingEnabled: true,
      );

      expect(config.isEnabled, true);
      expect(config.isAutomatedTrackingEnabled, true);
    });

    test('should handle disabled with automated tracking', () {
      final config = NavigationModuleConfiguration(
        isEnabled: false,
        isAutomatedTrackingEnabled: true,
      );

      expect(config.isEnabled, false);
      expect(config.isAutomatedTrackingEnabled, true);
    });
  });

  group('CrashReportsModuleConfiguration', () {
    test('should create with default enabled', () {
      final config = CrashReportsModuleConfiguration();

      expect(config.isEnabled, true);
    });

    test('should create with disabled', () {
      final config = CrashReportsModuleConfiguration(isEnabled: false);

      expect(config.isEnabled, false);
    });
  });

  group('InteractionsModuleConfiguration', () {
    test('should create with default enabled', () {
      final config = InteractionsModuleConfiguration();

      expect(config.isEnabled, true);
    });

    test('should create with disabled', () {
      final config = InteractionsModuleConfiguration(isEnabled: false);

      expect(config.isEnabled, false);
    });
  });

  group('NetworkMonitorModuleConfiguration', () {
    test('should create with default enabled', () {
      final config = NetworkMonitorModuleConfiguration();

      expect(config.isEnabled, true);
    });

    test('should create with disabled', () {
      final config = NetworkMonitorModuleConfiguration(isEnabled: false);

      expect(config.isEnabled, false);
    });
  });

  group('AnrModuleConfiguration', () {
    test('should create with default enabled', () {
      final config = AnrModuleConfiguration();

      expect(config.isEnabled, true);
    });

    test('should create with disabled', () {
      final config = AnrModuleConfiguration(isEnabled: false);

      expect(config.isEnabled, false);
    });
  });

  group('HttpUrlModuleConfiguration', () {
    test('should create with default values', () {
      final config = HttpUrlModuleConfiguration();

      expect(config.isEnabled, true);
      expect(config.capturedRequestHeaders, isEmpty);
      expect(config.capturedResponseHeaders, isEmpty);
    });

    test('should create with custom values', () {
      final config = HttpUrlModuleConfiguration(
        isEnabled: false,
        capturedRequestHeaders: ['Authorization', 'Content-Type'],
        capturedResponseHeaders: ['Set-Cookie', 'Cache-Control'],
      );

      expect(config.isEnabled, false);
      expect(config.capturedRequestHeaders, ['Authorization', 'Content-Type']);
      expect(config.capturedResponseHeaders, ['Set-Cookie', 'Cache-Control']);
    });

    test('should handle empty lists', () {
      final config = HttpUrlModuleConfiguration(
        capturedRequestHeaders: [],
        capturedResponseHeaders: [],
      );

      expect(config.capturedRequestHeaders, isEmpty);
      expect(config.capturedResponseHeaders, isEmpty);
    });
  });

  group('OkHttp3AutoModuleConfiguration', () {
    test('should create with default values', () {
      final config = OkHttp3AutoModuleConfiguration();

      expect(config.isEnabled, true);
      expect(config.capturedRequestHeaders, isEmpty);
      expect(config.capturedResponseHeaders, isEmpty);
    });

    test('should create with custom values', () {
      final config = OkHttp3AutoModuleConfiguration(
        isEnabled: false,
        capturedRequestHeaders: ['User-Agent'],
        capturedResponseHeaders: ['X-Response-Time'],
      );

      expect(config.isEnabled, false);
      expect(config.capturedRequestHeaders, ['User-Agent']);
      expect(config.capturedResponseHeaders, ['X-Response-Time']);
    });
  });

  group('NetworkInstrumentationModuleConfiguration', () {
    test('should create with default values', () {
      final config = NetworkInstrumentationModuleConfiguration();

      expect(config.isEnabled, true);
      expect(config.ignoreURLs, isEmpty);
    });

    test('should create with custom values', () {
      final ignoreURLs = [
        RegularExpression(pattern: r'.*\.example\.com'),
        RegularExpression(pattern: r'http://localhost.*'),
      ];

      final config = NetworkInstrumentationModuleConfiguration(
        isEnabled: false,
        ignoreURLs: ignoreURLs,
      );

      expect(config.isEnabled, false);
      expect(config.ignoreURLs.length, 2);
      expect(config.ignoreURLs[0].pattern, r'.*\.example\.com');
      expect(config.ignoreURLs[1].pattern, r'http://localhost.*');
    });
  });

  group('RegularExpression', () {
    test('should create without options', () {
      final regex = RegularExpression(pattern: r'\d+');

      expect(regex.pattern, r'\d+');
      expect(regex.options, isNull);
    });

    test('should create with options', () {
      final regex = RegularExpression(
        pattern: r'[a-z]+',
        options: [
          RegexOption.caseInsensitive,
          RegexOption.dotMatchesLineSeparators,
        ],
      );

      expect(regex.pattern, r'[a-z]+');
      expect(regex.options?.length, 2);
      expect(regex.options, contains(RegexOption.caseInsensitive));
      expect(regex.options, contains(RegexOption.dotMatchesLineSeparators));
    });

    test('should create with all options', () {
      final regex = RegularExpression(
        pattern: r'test',
        options: [
          RegexOption.caseInsensitive,
          RegexOption.allowCommentsAndWhitespace,
          RegexOption.ignoreMetacharacters,
          RegexOption.dotMatchesLineSeparators,
          RegexOption.anchorsMatchLines,
          RegexOption.useUnixLineSeparators,
          RegexOption.useUnicodeWordBoundaries,
        ],
      );

      expect(regex.options?.length, 7);
    });
  });

  group('RegularExpression Conversion', () {
    test('should convert to GeneratedRegularExpression without options', () {
      final regex = RegularExpression(pattern: r'test');
      final generated = regex.toGeneratedRegularExpression();

      expect(generated.pattern, r'test');
      expect(generated.options, isNull);
    });

    test('should convert to GeneratedRegularExpression with options', () {
      final regex = RegularExpression(
        pattern: r'test',
        options: [
          RegexOption.caseInsensitive,
          RegexOption.dotMatchesLineSeparators,
        ],
      );
      final generated = regex.toGeneratedRegularExpression();

      expect(generated.pattern, r'test');
      expect(generated.options?.length, 2);
      expect(generated.options, contains(GeneratedRegexOption.caseInsensitive));
      expect(
        generated.options,
        contains(GeneratedRegexOption.dotMatchesLineSeparators),
      );
    });

    test('should convert all RegexOption values correctly', () {
      final mappings = {
        RegexOption.caseInsensitive: GeneratedRegexOption.caseInsensitive,
        RegexOption.allowCommentsAndWhitespace:
            GeneratedRegexOption.allowCommentsAndWhitespace,
        RegexOption.ignoreMetacharacters:
            GeneratedRegexOption.ignoreMetacharacters,
        RegexOption.dotMatchesLineSeparators:
            GeneratedRegexOption.dotMatchesLineSeparators,
        RegexOption.anchorsMatchLines: GeneratedRegexOption.anchorsMatchLines,
        RegexOption.useUnixLineSeparators:
            GeneratedRegexOption.useUnixLineSeparators,
        RegexOption.useUnicodeWordBoundaries:
            GeneratedRegexOption.useUnicodeWordBoundaries,
      };

      for (final entry in mappings.entries) {
        final regex = RegularExpression(pattern: 'test', options: [entry.key]);
        final generated = regex.toGeneratedRegularExpression();
        expect(generated.options, contains(entry.value));
      }
    });

    test('should convert from GeneratedRegularExpression without options', () {
      final generated = GeneratedRegularExpression(pattern: r'test');
      final regex = generated.toRegularExpression();

      expect(regex.pattern, r'test');
      expect(regex.options, isNull);
    });

    test('should convert from GeneratedRegularExpression with options', () {
      final generated = GeneratedRegularExpression(
        pattern: r'test',
        options: [
          GeneratedRegexOption.caseInsensitive,
          GeneratedRegexOption.anchorsMatchLines,
        ],
      );
      final regex = generated.toRegularExpression();

      expect(regex.pattern, r'test');
      expect(regex.options?.length, 2);
      expect(regex.options, contains(RegexOption.caseInsensitive));
      expect(regex.options, contains(RegexOption.anchorsMatchLines));
    });
  });

  group('RegularExpression List Conversion', () {
    test('should convert list to generated list', () {
      final regexList = [
        RegularExpression(pattern: r'pattern1'),
        RegularExpression(
          pattern: r'pattern2',
          options: [RegexOption.caseInsensitive],
        ),
      ];

      final generatedList = regexList.toGeneratedList();

      expect(generatedList.length, 2);
      expect(generatedList[0].pattern, r'pattern1');
      expect(generatedList[1].pattern, r'pattern2');
      expect(
        generatedList[1].options,
        contains(GeneratedRegexOption.caseInsensitive),
      );
    });

    test('should convert generated list to list', () {
      final generatedList = [
        GeneratedRegularExpression(pattern: r'pattern1'),
        GeneratedRegularExpression(
          pattern: r'pattern2',
          options: [GeneratedRegexOption.dotMatchesLineSeparators],
        ),
      ];

      final regexList = generatedList.toRegularExpressionList();

      expect(regexList.length, 2);
      expect(regexList[0].pattern, r'pattern1');
      expect(regexList[1].pattern, r'pattern2');
      expect(
        regexList[1].options,
        contains(RegexOption.dotMatchesLineSeparators),
      );
    });

    test('should handle empty list conversion', () {
      final regexList = <RegularExpression>[];
      final generatedList = regexList.toGeneratedList();

      expect(generatedList, isEmpty);

      final emptyGenerated = <GeneratedRegularExpression>[];
      final emptyRegex = emptyGenerated.toRegularExpressionList();

      expect(emptyRegex, isEmpty);
    });
  });

  group('SessionReplayModuleConfiguration', () {
    test('should create with default values', () {
      final config = SessionReplayModuleConfiguration();

      expect(config.isEnabled, true);
      expect(config.samplingRate, 0.2);
    });

    test('should create with custom values', () {
      final config = SessionReplayModuleConfiguration(
        isEnabled: false,
        samplingRate: 0.5,
      );

      expect(config.isEnabled, false);
      expect(config.samplingRate, 0.5);
    });

    test('samplingRate of 0.0 should be valid', () {
      final config = SessionReplayModuleConfiguration(samplingRate: 0.0);
      expect(config.samplingRate, 0.0);
    });

    test('samplingRate of 1.0 should be valid', () {
      final config = SessionReplayModuleConfiguration(samplingRate: 1.0);
      expect(config.samplingRate, 1.0);
    });

    test('samplingRate less than 0.0 should be clamped to 0.0', () {
      final config = SessionReplayModuleConfiguration(samplingRate: -0.1);
      expect(config.samplingRate, 0.0);
    });

    test('samplingRate greater than 1.0 should be clamped to 1.0', () {
      final config = SessionReplayModuleConfiguration(samplingRate: 1.1);
      expect(config.samplingRate, 1.0);
    });
  });

  group('Module Configuration Hierarchy', () {
    test(
      'all activable modules should extend ActivableModuleConfiguration',
      () {
        final configs = [
          SlowRenderingModuleConfiguration(),
          NavigationModuleConfiguration(),
          CrashReportsModuleConfiguration(),
          InteractionsModuleConfiguration(),
          NetworkMonitorModuleConfiguration(),
          AnrModuleConfiguration(),
          HttpUrlModuleConfiguration(),
          OkHttp3AutoModuleConfiguration(),
          NetworkInstrumentationModuleConfiguration(),
          SessionReplayModuleConfiguration(),
        ];

        for (final config in configs) {
          expect(config, isA<ActivableModuleConfiguration>());
          expect(config, isA<ModuleConfiguration>());
        }
      },
    );
  });

  group('RegexOption Enum', () {
    test('should have all expected enum values', () {
      final allOptions = RegexOption.values;

      expect(allOptions.length, 7);
      expect(allOptions, contains(RegexOption.caseInsensitive));
      expect(allOptions, contains(RegexOption.allowCommentsAndWhitespace));
      expect(allOptions, contains(RegexOption.ignoreMetacharacters));
      expect(allOptions, contains(RegexOption.dotMatchesLineSeparators));
      expect(allOptions, contains(RegexOption.anchorsMatchLines));
      expect(allOptions, contains(RegexOption.useUnixLineSeparators));
      expect(allOptions, contains(RegexOption.useUnicodeWordBoundaries));
    });
  });
}
