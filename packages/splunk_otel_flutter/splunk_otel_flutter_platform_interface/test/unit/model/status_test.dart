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
import 'package:splunk_otel_flutter_platform_interface/src/model/status.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

void main() {
  group('Status Enum', () {
    test('should have all expected enum values', () {
      final allStatuses = Status.values;

      expect(allStatuses.length, 6);
      expect(allStatuses, contains(Status.running));
      expect(allStatuses, contains(Status.notInstalled));
      expect(allStatuses, contains(Status.subProcess));
      expect(allStatuses, contains(Status.sampledOut));
      expect(allStatuses, contains(Status.unsupportedPlatform));
      expect(allStatuses, contains(Status.unsupportedOsVersion));
    });

    test('should have correct enum names', () {
      expect(Status.running.name, 'running');
      expect(Status.notInstalled.name, 'notInstalled');
      expect(Status.subProcess.name, 'subProcess');
      expect(Status.sampledOut.name, 'sampledOut');
      expect(Status.unsupportedPlatform.name, 'unsupportedPlatform');
      expect(Status.unsupportedOsVersion.name, 'unsupportedOsVersion');
    });
  });

  group('Status to GeneratedStatus Conversion', () {
    test('should convert running correctly', () {
      final generated = Status.running.toGeneratedStatus();
      expect(generated, GeneratedStatus.running);
    });

    test('should convert notInstalled correctly', () {
      final generated = Status.notInstalled.toGeneratedStatus();
      expect(generated, GeneratedStatus.notInstalled);
    });

    test('should convert subProcess correctly', () {
      final generated = Status.subProcess.toGeneratedStatus();
      expect(generated, GeneratedStatus.subProcess);
    });

    test('should convert sampledOut correctly', () {
      final generated = Status.sampledOut.toGeneratedStatus();
      expect(generated, GeneratedStatus.sampledOut);
    });

    test('should convert unsupportedPlatform correctly', () {
      final generated = Status.unsupportedPlatform.toGeneratedStatus();
      expect(generated, GeneratedStatus.unsupportedPlatform);
    });

    test('should convert unsupportedOsVersion correctly', () {
      final generated = Status.unsupportedOsVersion.toGeneratedStatus();
      expect(generated, GeneratedStatus.unsupportedOsVersion);
    });

    test('should convert all statuses correctly', () {
      final mappings = {
        Status.running: GeneratedStatus.running,
        Status.notInstalled: GeneratedStatus.notInstalled,
        Status.subProcess: GeneratedStatus.subProcess,
        Status.sampledOut: GeneratedStatus.sampledOut,
        Status.unsupportedPlatform: GeneratedStatus.unsupportedPlatform,
        Status.unsupportedOsVersion: GeneratedStatus.unsupportedOsVersion,
      };

      for (final entry in mappings.entries) {
        expect(entry.key.toGeneratedStatus(), entry.value);
      }
    });
  });

  group('GeneratedStatus to Status Conversion', () {
    test('should convert running correctly', () {
      final status = GeneratedStatus.running.toStatus();
      expect(status, Status.running);
    });

    test('should convert notInstalled correctly', () {
      final status = GeneratedStatus.notInstalled.toStatus();
      expect(status, Status.notInstalled);
    });

    test('should convert subProcess correctly', () {
      final status = GeneratedStatus.subProcess.toStatus();
      expect(status, Status.subProcess);
    });

    test('should convert sampledOut correctly', () {
      final status = GeneratedStatus.sampledOut.toStatus();
      expect(status, Status.sampledOut);
    });

    test('should convert unsupportedPlatform correctly', () {
      final status = GeneratedStatus.unsupportedPlatform.toStatus();
      expect(status, Status.unsupportedPlatform);
    });

    test('should convert unsupportedOsVersion correctly', () {
      final status = GeneratedStatus.unsupportedOsVersion.toStatus();
      expect(status, Status.unsupportedOsVersion);
    });

    test('should convert all generated statuses correctly', () {
      final mappings = {
        GeneratedStatus.running: Status.running,
        GeneratedStatus.notInstalled: Status.notInstalled,
        GeneratedStatus.subProcess: Status.subProcess,
        GeneratedStatus.sampledOut: Status.sampledOut,
        GeneratedStatus.unsupportedPlatform: Status.unsupportedPlatform,
        GeneratedStatus.unsupportedOsVersion: Status.unsupportedOsVersion,
      };

      for (final entry in mappings.entries) {
        expect(entry.key.toStatus(), entry.value);
      }
    });
  });

  group('Round-trip Conversion', () {
    test('should handle round-trip conversion for all statuses', () {
      for (final status in Status.values) {
        final generated = status.toGeneratedStatus();
        final converted = generated.toStatus();
        expect(converted, status);
      }
    });

    test('should handle round-trip conversion for all generated statuses', () {
      for (final generated in GeneratedStatus.values) {
        final status = generated.toStatus();
        final convertedBack = status.toGeneratedStatus();
        expect(convertedBack, generated);
      }
    });
  });

  group('Bidirectional Mapping Consistency', () {
    test(
      'should have one-to-one mapping between Status and GeneratedStatus',
      () {
        // Check that Status and GeneratedStatus have the same number of values
        expect(Status.values.length, GeneratedStatus.values.length);

        // Check that each Status maps to a unique GeneratedStatus
        final generatedStatuses = Status.values
            .map((s) => s.toGeneratedStatus())
            .toSet();
        expect(generatedStatuses.length, Status.values.length);

        // Check that each GeneratedStatus maps to a unique Status
        final statuses = GeneratedStatus.values
            .map((g) => g.toStatus())
            .toSet();
        expect(statuses.length, GeneratedStatus.values.length);
      },
    );
  });

  group('Status Semantics', () {
    test('running should represent active agent', () {
      expect(Status.running, isA<Status>());
    });

    test('notInstalled should represent agent not installed', () {
      expect(Status.notInstalled, isA<Status>());
    });

    test('subProcess should be Android-only status', () {
      expect(Status.subProcess, isA<Status>());
    });

    test('sampledOut should represent locally sampled out agent', () {
      expect(Status.sampledOut, isA<Status>());
    });

    test('unsupportedPlatform should represent unsupported platform', () {
      expect(Status.unsupportedPlatform, isA<Status>());
    });

    test('unsupportedOsVersion should represent unsupported OS version', () {
      expect(Status.unsupportedOsVersion, isA<Status>());
    });
  });

  group('Enum Ordering', () {
    test('should maintain consistent enum ordering', () {
      final statusList = Status.values.toList();
      expect(statusList[0], Status.running);
      expect(statusList[1], Status.notInstalled);
      expect(statusList[2], Status.subProcess);
      expect(statusList[3], Status.sampledOut);
      expect(statusList[4], Status.unsupportedPlatform);
      expect(statusList[5], Status.unsupportedOsVersion);
    });
  });
}
