import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class GlobalAttributes {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<MutableAttributeValue> globalAttributesGet({
    required String key,
  }) async =>
      _delegate.globalAttributesGet(key: key);

  Future<MutableAttributes> globalAttributesGetAll() async =>
      _delegate.globalAttributesGetAll();

  Future<void> globalAttributesRemove({
    required String key,
  }) async =>
      await _delegate.globalAttributesRemove(key: key);

  Future<void> globalAttributesRemoveAll() async =>
      await _delegate.globalAttributesRemoveAll();

  Future<bool> globalAttributesContains({
    required String key,
  }) async =>
      await _delegate.globalAttributesContains(key: key);

  Future<void> globalAttributesSetString({
    required String key,
    required String? value,
  }) async =>
      await _delegate.globalAttributesSetString(key: key, value: value);

  Future<void> globalAttributesSetInt({
    required String key,
    required int? value,
  }) async =>
      await _delegate.globalAttributesSetInt(key: key, value: value);

  Future<void> globalAttributesSetDouble({
    required String key,
    required double? value,
  }) async =>
      await _delegate.globalAttributesSetDouble(key: key, value: value);

  Future<void> globalAttributesSetBool({
    required String key,
    required bool? value,
  }) async =>
      await _delegate.globalAttributesSetBool(key: key, value: value);

  Future<void> globalAttributesSetStringList({
    required String key,
    required List<String>? value,
  }) async =>
      await _delegate.globalAttributesSetStringList(key: key, value: value);

  Future<void> globalAttributesSetIntList({
    required String key,
    required List<int>? value,
  }) async =>
      await _delegate.globalAttributesSetIntList(key: key, value: value);

  Future<void> globalAttributesSetDoubleList({
    required String key,
    required List<double>? value,
  }) async =>
      await _delegate.globalAttributesSetDoubleList(key: key, value: value);

  Future<void> globalAttributesSetBoolList({
    required String key,
    required List<bool>? value,
  }) async =>
      await _delegate.globalAttributesSetBoolList(key: key, value: value);

  Future<void> globalAttributesSetAll(
          {required String key, required MutableAttributes attributes}) async =>
      await _delegate.globalAttributesSetAll(key: key, attributes: attributes);
}
