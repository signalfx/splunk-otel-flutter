import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class GlobalAttributes {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<MutableAttributeValue> get({
    required String key,
  }) async =>
      _delegate.globalAttributesGet(key: key);

  Future<MutableAttributes> etAll() async =>
      _delegate.globalAttributesGetAll();

  Future<void> remove({
    required String key,
  }) async =>
      await _delegate.globalAttributesRemove(key: key);

  Future<void> removeAll() async =>
      await _delegate.globalAttributesRemoveAll();

  Future<bool> contains({
    required String key,
  }) async =>
      await _delegate.globalAttributesContains(key: key);

  Future<void> setString({
    required String key,
    required String value,
  }) async =>
      await _delegate.globalAttributesSetString(key: key, value: value);

  Future<void> setInt({
    required String key,
    required int value,
  }) async =>
      await _delegate.globalAttributesSetInt(key: key, value: value);

  Future<void> etDouble({
    required String key,
    required double value,
  }) async =>
      await _delegate.globalAttributesSetDouble(key: key, value: value);

  Future<void> setBool({
    required String key,
    required bool value,
  }) async =>
      await _delegate.globalAttributesSetBool(key: key, value: value);

  Future<void> setStringList({
    required String key,
    required List<String> value,
  }) async =>
      await _delegate.globalAttributesSetStringList(key: key, value: value);

  Future<void> setIntList({
    required String key,
    required List<int> value,
  }) async =>
      await _delegate.globalAttributesSetIntList(key: key, value: value);

  Future<void> setDoubleList({
    required String key,
    required List<double> value,
  }) async =>
      await _delegate.globalAttributesSetDoubleList(key: key, value: value);

  Future<void> setBoolList({
    required String key,
    required List<bool> value,
  }) async =>
      await _delegate.globalAttributesSetBoolList(key: key, value: value);

  Future<void> setAll(
          {required String key, required MutableAttributes attributes}) async =>
      await _delegate.globalAttributesSetAll(key: key, attributes: attributes);
}
