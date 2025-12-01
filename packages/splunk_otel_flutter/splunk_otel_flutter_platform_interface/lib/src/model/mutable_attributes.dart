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

class MutableAttributes {
  final Map<String, MutableAttributeValue> attributes;

  MutableAttributes({this.attributes = const {}});
}

abstract class MutableAttributeValue {}

class MutableAttributeInt extends MutableAttributeValue {
  final int value;

  MutableAttributeInt({required this.value});
}

class MutableAttributeDouble extends MutableAttributeValue {
  final double value;

  MutableAttributeDouble({required this.value});
}

class MutableAttributeString extends MutableAttributeValue {
  final String value;

  MutableAttributeString({required this.value});
}

class MutableAttributeBool extends MutableAttributeValue {
  final bool value;

  MutableAttributeBool({required this.value});
}

class MutableAttributeListInt extends MutableAttributeValue {
  final List<int> value;

  MutableAttributeListInt({required this.value});
}

class MutableAttributeListDouble extends MutableAttributeValue {
  final List<double> value;

  MutableAttributeListDouble({required this.value});
}

class MutableAttributeListString extends MutableAttributeValue {
  final List<String> value;

  MutableAttributeListString({required this.value});
}

class MutableAttributeListBool extends MutableAttributeValue {
  final List<bool> value;

  MutableAttributeListBool({required this.value});
}

extension MutableAttributesConverter on MutableAttributes {
  GeneratedMutableAttributes toGeneratedMutableAttributes() {
    final Map<String, Object?> generatedAttributes = {};
    attributes.forEach((key, value) {
      if (value is MutableAttributeInt) {
        generatedAttributes[key] =
            GeneratedMutableAttributeInt(value: value.value);
      } else if (value is MutableAttributeDouble) {
        generatedAttributes[key] =
            GeneratedMutableAttributeDouble(value: value.value);
      } else if (value is MutableAttributeString) {
        generatedAttributes[key] =
            GeneratedMutableAttributeString(value: value.value);
      } else if (value is MutableAttributeBool) {
        generatedAttributes[key] =
            GeneratedMutableAttributeBool(value: value.value);
      } else if (value is MutableAttributeListInt) {
        generatedAttributes[key] =
            GeneratedMutableAttributeListInt(value: value.value);
      } else if (value is MutableAttributeListDouble) {
        generatedAttributes[key] =
            GeneratedMutableAttributeListDouble(value: value.value);
      } else if (value is MutableAttributeListString) {
        generatedAttributes[key] =
            GeneratedMutableAttributeListString(value: value.value);
      } else if (value is MutableAttributeListBool) {
        generatedAttributes[key] =
            GeneratedMutableAttributeListBool(value: value.value);
      }
    });
    return GeneratedMutableAttributes(attributes: generatedAttributes);
  }
}

extension GeneratedMutableAttributesConverter on GeneratedMutableAttributes {
  MutableAttributes toMutableAttributes() {
    final Map<String, MutableAttributeValue> mutableAttributes = {};
    attributes.forEach((key, value) {
      if (value is GeneratedMutableAttributeInt) {
        mutableAttributes[key] = MutableAttributeInt(value: value.value);
      } else if (value is GeneratedMutableAttributeDouble) {
        mutableAttributes[key] = MutableAttributeDouble(value: value.value);
      } else if (value is GeneratedMutableAttributeString) {
        mutableAttributes[key] = MutableAttributeString(value: value.value);
      } else if (value is GeneratedMutableAttributeBool) {
        mutableAttributes[key] = MutableAttributeBool(value: value.value);
      } else if (value is GeneratedMutableAttributeListInt) {
        mutableAttributes[key] = MutableAttributeListInt(value: value.value);
      } else if (value is GeneratedMutableAttributeListDouble) {
        mutableAttributes[key] = MutableAttributeListDouble(value: value.value);
      } else if (value is GeneratedMutableAttributeListString) {
        mutableAttributes[key] = MutableAttributeListString(value: value.value);
      } else if (value is GeneratedMutableAttributeListBool) {
        mutableAttributes[key] = MutableAttributeListBool(value: value.value);
      }
    });
    return MutableAttributes(attributes: mutableAttributes);
  }
}

extension DynamicToMutableAttributeValueConverter on dynamic {
  MutableAttributeValue toMutableAttributeValue() {
    if (this is GeneratedMutableAttributeInt) {
      return MutableAttributeInt(value: (this as GeneratedMutableAttributeInt).value);
    } else if (this is GeneratedMutableAttributeDouble) {
      return MutableAttributeDouble(value: (this as GeneratedMutableAttributeDouble).value);
    } else if (this is GeneratedMutableAttributeString) {
      return MutableAttributeString(value: (this as GeneratedMutableAttributeString).value);
    } else if (this is GeneratedMutableAttributeBool) {
      return MutableAttributeBool(value: (this as GeneratedMutableAttributeBool).value);
    } else if (this is GeneratedMutableAttributeListInt) {
      return MutableAttributeListInt(value: (this as GeneratedMutableAttributeListInt).value);
    } else if (this is GeneratedMutableAttributeListDouble) {
      return MutableAttributeListDouble(value: (this as GeneratedMutableAttributeListDouble).value);
    } else if (this is GeneratedMutableAttributeListString) {
      return MutableAttributeListString(value: (this as GeneratedMutableAttributeListString).value);
    } else if (this is GeneratedMutableAttributeListBool) {
      return MutableAttributeListBool(value: (this as GeneratedMutableAttributeListBool).value);
    }
    throw ArgumentError('Unsupported GeneratedMutableAttribute type: $runtimeType');
  }
}
