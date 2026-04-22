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
import 'package:splunk_otel_flutter_platform_interface/src/model/mutable_attributes.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

void main() {
  group('MutableAttributes', () {
    test('should create empty attributes', () {
      final attributes = const MutableAttributes();

      expect(attributes.attributes, isEmpty);
    });

    test('should create with attributes map', () {
      final attributes = MutableAttributes(
        attributes: {
          'key1': MutableAttributeString(value: 'value1'),
          'key2': MutableAttributeInt(value: 42),
        },
      );

      expect(attributes.attributes.length, 2);
      expect(attributes.attributes['key1'], isA<MutableAttributeString>());
      expect(attributes.attributes['key2'], isA<MutableAttributeInt>());
    });
  });

  group('MutableAttributeInt', () {
    test('should create with value', () {
      final attribute = MutableAttributeInt(value: 123);

      expect(attribute.value, 123);
      expect(attribute, isA<MutableAttributeValue>());
    });

    test('should handle negative values', () {
      final attribute = MutableAttributeInt(value: -456);

      expect(attribute.value, -456);
    });

    test('should handle zero', () {
      final attribute = MutableAttributeInt(value: 0);

      expect(attribute.value, 0);
    });

    test('should handle large values', () {
      final attribute = MutableAttributeInt(
        value: 9223372036854775807,
      ); // max int64

      expect(attribute.value, 9223372036854775807);
    });
  });

  group('MutableAttributeDouble', () {
    test('should create with value', () {
      final attribute = MutableAttributeDouble(value: 3.14);

      expect(attribute.value, 3.14);
      expect(attribute, isA<MutableAttributeValue>());
    });

    test('should handle negative values', () {
      final attribute = MutableAttributeDouble(value: -99.99);

      expect(attribute.value, -99.99);
    });

    test('should handle zero', () {
      final attribute = MutableAttributeDouble(value: 0.0);

      expect(attribute.value, 0.0);
    });

    test('should handle very small values', () {
      final attribute = MutableAttributeDouble(value: 0.000001);

      expect(attribute.value, closeTo(0.000001, 0.0000001));
    });

    test('should handle very large values', () {
      final attribute = MutableAttributeDouble(value: 1e308);

      expect(attribute.value, 1e308);
    });
  });

  group('MutableAttributeString', () {
    test('should create with value', () {
      final attribute = MutableAttributeString(value: 'test');

      expect(attribute.value, 'test');
      expect(attribute, isA<MutableAttributeValue>());
    });

    test('should handle empty string', () {
      final attribute = MutableAttributeString(value: '');

      expect(attribute.value, '');
    });

    test('should handle long strings', () {
      final longString = 'a' * 10000;
      final attribute = MutableAttributeString(value: longString);

      expect(attribute.value, longString);
      expect(attribute.value.length, 10000);
    });

    test('should handle special characters', () {
      final attribute = MutableAttributeString(
        value: '!@#\$%^&*()_+-=[]{}|;:,.<>?/~`',
      );

      expect(attribute.value, '!@#\$%^&*()_+-=[]{}|;:,.<>?/~`');
    });

    test('should handle unicode characters', () {
      final attribute = MutableAttributeString(value: '你好世界🌍');

      expect(attribute.value, '你好世界🌍');
    });
  });

  group('MutableAttributeBool', () {
    test('should create with true', () {
      final attribute = MutableAttributeBool(value: true);

      expect(attribute.value, true);
      expect(attribute, isA<MutableAttributeValue>());
    });

    test('should create with false', () {
      final attribute = MutableAttributeBool(value: false);

      expect(attribute.value, false);
    });
  });

  group('MutableAttributes Conversion to Generated', () {
    test('should convert empty attributes', () {
      final attributes = const MutableAttributes();
      final generated = attributes.toGeneratedMutableAttributes();

      expect(generated.attributes, isEmpty);
    });

    test('should convert string attribute', () {
      final attributes = MutableAttributes(
        attributes: {'key': MutableAttributeString(value: 'test')},
      );
      final generated = attributes.toGeneratedMutableAttributes();

      expect(generated.attributes.length, 1);
      expect(
        generated.attributes['key'],
        isA<GeneratedMutableAttributeString>(),
      );
      expect(
        (generated.attributes['key'] as GeneratedMutableAttributeString).value,
        'test',
      );
    });

    test('should convert int attribute', () {
      final attributes = MutableAttributes(
        attributes: {'key': MutableAttributeInt(value: 42)},
      );
      final generated = attributes.toGeneratedMutableAttributes();

      expect(generated.attributes.length, 1);
      expect(generated.attributes['key'], isA<GeneratedMutableAttributeInt>());
      expect(
        (generated.attributes['key'] as GeneratedMutableAttributeInt).value,
        42,
      );
    });

    test('should convert double attribute', () {
      final attributes = MutableAttributes(
        attributes: {'key': MutableAttributeDouble(value: 3.14)},
      );
      final generated = attributes.toGeneratedMutableAttributes();

      expect(generated.attributes.length, 1);
      expect(
        generated.attributes['key'],
        isA<GeneratedMutableAttributeDouble>(),
      );
      expect(
        (generated.attributes['key'] as GeneratedMutableAttributeDouble).value,
        3.14,
      );
    });

    test('should convert bool attribute', () {
      final attributes = MutableAttributes(
        attributes: {'key': MutableAttributeBool(value: true)},
      );
      final generated = attributes.toGeneratedMutableAttributes();

      expect(generated.attributes.length, 1);
      expect(generated.attributes['key'], isA<GeneratedMutableAttributeBool>());
      expect(
        (generated.attributes['key'] as GeneratedMutableAttributeBool).value,
        true,
      );
    });

    test('should convert mixed attributes', () {
      final attributes = MutableAttributes(
        attributes: {
          'string_key': MutableAttributeString(value: 'text'),
          'int_key': MutableAttributeInt(value: 100),
          'double_key': MutableAttributeDouble(value: 99.99),
          'bool_key': MutableAttributeBool(value: false),
        },
      );
      final generated = attributes.toGeneratedMutableAttributes();

      expect(generated.attributes.length, 4);
      expect(
        generated.attributes['string_key'],
        isA<GeneratedMutableAttributeString>(),
      );
      expect(
        generated.attributes['int_key'],
        isA<GeneratedMutableAttributeInt>(),
      );
      expect(
        generated.attributes['double_key'],
        isA<GeneratedMutableAttributeDouble>(),
      );
      expect(
        generated.attributes['bool_key'],
        isA<GeneratedMutableAttributeBool>(),
      );
    });
  });

  group('GeneratedMutableAttributes Conversion to MutableAttributes', () {
    test('should convert empty attributes', () {
      final generated = GeneratedMutableAttributes(attributes: {});
      final attributes = generated.toMutableAttributes();

      expect(attributes.attributes, isEmpty);
    });

    test('should convert string attribute', () {
      final generated = GeneratedMutableAttributes(
        attributes: {'key': GeneratedMutableAttributeString(value: 'test')},
      );
      final attributes = generated.toMutableAttributes();

      expect(attributes.attributes.length, 1);
      expect(attributes.attributes['key'], isA<MutableAttributeString>());
      expect(
        (attributes.attributes['key'] as MutableAttributeString).value,
        'test',
      );
    });

    test('should convert int attribute', () {
      final generated = GeneratedMutableAttributes(
        attributes: {'key': GeneratedMutableAttributeInt(value: 42)},
      );
      final attributes = generated.toMutableAttributes();

      expect(attributes.attributes.length, 1);
      expect(attributes.attributes['key'], isA<MutableAttributeInt>());
      expect((attributes.attributes['key'] as MutableAttributeInt).value, 42);
    });

    test('should convert double attribute', () {
      final generated = GeneratedMutableAttributes(
        attributes: {'key': GeneratedMutableAttributeDouble(value: 3.14)},
      );
      final attributes = generated.toMutableAttributes();

      expect(attributes.attributes.length, 1);
      expect(attributes.attributes['key'], isA<MutableAttributeDouble>());
      expect(
        (attributes.attributes['key'] as MutableAttributeDouble).value,
        3.14,
      );
    });

    test('should convert bool attribute', () {
      final generated = GeneratedMutableAttributes(
        attributes: {'key': GeneratedMutableAttributeBool(value: true)},
      );
      final attributes = generated.toMutableAttributes();

      expect(attributes.attributes.length, 1);
      expect(attributes.attributes['key'], isA<MutableAttributeBool>());
      expect(
        (attributes.attributes['key'] as MutableAttributeBool).value,
        true,
      );
    });

    test('should convert mixed attributes', () {
      final generated = GeneratedMutableAttributes(
        attributes: {
          'string_key': GeneratedMutableAttributeString(value: 'text'),
          'int_key': GeneratedMutableAttributeInt(value: 100),
          'double_key': GeneratedMutableAttributeDouble(value: 99.99),
          'bool_key': GeneratedMutableAttributeBool(value: false),
        },
      );
      final attributes = generated.toMutableAttributes();

      expect(attributes.attributes.length, 4);
      expect(
        attributes.attributes['string_key'],
        isA<MutableAttributeString>(),
      );
      expect(attributes.attributes['int_key'], isA<MutableAttributeInt>());
      expect(
        attributes.attributes['double_key'],
        isA<MutableAttributeDouble>(),
      );
      expect(attributes.attributes['bool_key'], isA<MutableAttributeBool>());
    });
  });

  group('Round-trip Conversion', () {
    test('should handle round-trip conversion for all types', () {
      final original = MutableAttributes(
        attributes: {
          'string': MutableAttributeString(value: 'test'),
          'int': MutableAttributeInt(value: 42),
          'double': MutableAttributeDouble(value: 3.14),
          'bool': MutableAttributeBool(value: true),
        },
      );

      final generated = original.toGeneratedMutableAttributes();
      final converted = generated.toMutableAttributes();

      expect(converted.attributes.length, 4);
      expect(
        (converted.attributes['string'] as MutableAttributeString).value,
        'test',
      );
      expect((converted.attributes['int'] as MutableAttributeInt).value, 42);
      expect(
        (converted.attributes['double'] as MutableAttributeDouble).value,
        3.14,
      );
      expect(
        (converted.attributes['bool'] as MutableAttributeBool).value,
        true,
      );
    });

    test('should handle empty attributes round-trip', () {
      final original = const MutableAttributes();
      final generated = original.toGeneratedMutableAttributes();
      final converted = generated.toMutableAttributes();

      expect(converted.attributes, isEmpty);
    });
  });

  group('Null handling', () {
    test('should handle null values in generated attributes', () {
      final generated = GeneratedMutableAttributes(attributes: {});
      final attributes = generated.toMutableAttributes();

      expect(attributes.attributes, isEmpty);
    });
  });
}
