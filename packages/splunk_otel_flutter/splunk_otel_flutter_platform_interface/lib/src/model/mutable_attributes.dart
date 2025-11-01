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
        generatedAttributes[key] = value.value;
      } else if (value is MutableAttributeDouble) {
        generatedAttributes[key] = value.value;
      } else if (value is MutableAttributeString) {
        generatedAttributes[key] = value.value;
      } else if (value is MutableAttributeBool) {
        generatedAttributes[key] = value.value;
      } else if (value is MutableAttributeListInt) {
        generatedAttributes[key] = value.value;
      } else if (value is MutableAttributeListDouble) {
        generatedAttributes[key] = value.value;
      } else if (value is MutableAttributeListString) {
        generatedAttributes[key] = value.value;
      } else if (value is MutableAttributeListBool) {
        generatedAttributes[key] = value.value;
      }
    });
    return GeneratedMutableAttributes(attributes: generatedAttributes);
  }
}

extension GeneratedMutableAttributesConverter on GeneratedMutableAttributes {
  MutableAttributes toMutableAttributes() {
    final Map<String, MutableAttributeValue> mutableAttributes = {};
    attributes.forEach((key, value) {
      if (value is int) {
        mutableAttributes[key] = MutableAttributeInt(value: value);
      } else if (value is double) {
        mutableAttributes[key] = MutableAttributeDouble(value: value);
      } else if (value is String) {
        mutableAttributes[key] = MutableAttributeString(value: value);
      } else if (value is bool) {
        mutableAttributes[key] = MutableAttributeBool(value: value);
      } else if (value is List<int>) {
        mutableAttributes[key] = MutableAttributeListInt(value: value);
      } else if (value is List<double>) {
        mutableAttributes[key] = MutableAttributeListDouble(value: value);
      } else if (value is List<String>) {
        mutableAttributes[key] = MutableAttributeListString(value: value);
      } else if (value is List<bool>) {
        mutableAttributes[key] = MutableAttributeListBool(value: value);
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
