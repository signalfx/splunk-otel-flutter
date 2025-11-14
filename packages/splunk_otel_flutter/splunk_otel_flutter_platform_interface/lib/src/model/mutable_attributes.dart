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

// Lists are currently set to private will be handled after first release
class _MutableAttributeListInt extends MutableAttributeValue {
  final List<int> value;

  _MutableAttributeListInt({required this.value});
}

class _MutableAttributeListDouble extends MutableAttributeValue {
  final List<double> value;

  _MutableAttributeListDouble({required this.value});
}

class _MutableAttributeListString extends MutableAttributeValue {
  final List<String> value;

  _MutableAttributeListString({required this.value});
}

class _MutableAttributeListBool extends MutableAttributeValue {
  final List<bool> value;

  _MutableAttributeListBool({required this.value});
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
      } else if (value is _MutableAttributeListInt) {
        generatedAttributes[key] =
            GeneratedMutableAttributeListInt(value: value.value);
      } else if (value is _MutableAttributeListDouble) {
        generatedAttributes[key] =
            GeneratedMutableAttributeListDouble(value: value.value);
      } else if (value is _MutableAttributeListString) {
        generatedAttributes[key] =
            GeneratedMutableAttributeListString(value: value.value);
      } else if (value is _MutableAttributeListBool) {
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
        mutableAttributes[key] = _MutableAttributeListInt(value: value.value);
      } else if (value is GeneratedMutableAttributeListDouble) {
        mutableAttributes[key] = _MutableAttributeListDouble(value: value.value);
      } else if (value is GeneratedMutableAttributeListString) {
        mutableAttributes[key] = _MutableAttributeListString(value: value.value);
      } else if (value is GeneratedMutableAttributeListBool) {
        mutableAttributes[key] = _MutableAttributeListBool(value: value.value);
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
