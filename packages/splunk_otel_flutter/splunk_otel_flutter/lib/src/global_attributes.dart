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

import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

/// Thread-safe mutable collection of attributes.
///
/// Attributes set via this API are sent with all telemetry signals (spans, events).
///
/// Access via `SplunkOtelFlutter.instance.globalAttributes`.
///
/// Example:
/// ```dart
/// final attrs = SplunkOtelFlutter.instance.globalAttributes;
///
/// await attrs.setString(key: 'user.name', value: 'Alice');
/// await attrs.setInt(key: 'user.loginCount', value: 5);
/// await attrs.setBool(key: 'user.isPremium', value: true);
///
/// final name = await attrs.get(key: 'user.name');
/// ```
class GlobalAttributes {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  /// Gets an attribute value (any type).
  ///
  /// [key] - Attribute key.
  ///
  /// Returns the value or `null` if not set.
  Future<MutableAttributeValue?> get({
    required String key,
  }) async =>
      _delegate.globalAttributesGet(key: key);

  /// Gets all attributes.
  ///
  /// Returns all key-value pairs.
  Future<MutableAttributes> getAll() async =>
      _delegate.globalAttributesGetAll();

  /// Removes an attribute.
  ///
  /// [key] - Attribute key.
  Future<void> remove({
    required String key,
  }) async =>
      await _delegate.globalAttributesRemove(key: key);

  /// Removes all attributes.
  Future<void> removeAll() async =>
      await _delegate.globalAttributesRemoveAll();

  /// Checks if an attribute exists.
  ///
  /// [key] - Attribute key.
  ///
  /// Returns `true` if attribute is set.
  Future<bool> contains({
    required String key,
  }) async =>
      await _delegate.globalAttributesContains(key: key);

  /// Sets a string attribute.
  ///
  /// [key] - Attribute key.
  /// [value] - String value.
  Future<void> setString({
    required String key,
    required String value,
  }) async =>
      await _delegate.globalAttributesSetString(key: key, value: value);

  /// Sets an integer attribute.
  ///
  /// [key] - Attribute key.
  /// [value] - Integer value.
  Future<void> setInt({
    required String key,
    required int value,
  }) async =>
      await _delegate.globalAttributesSetInt(key: key, value: value);

  /// Sets a double attribute.
  ///
  /// [key] - Attribute key.
  /// [value] - Double value.
  Future<void> setDouble({
    required String key,
    required double value,
  }) async =>
      await _delegate.globalAttributesSetDouble(key: key, value: value);

  /// Sets a boolean attribute.
  ///
  /// [key] - Attribute key.
  /// [value] - Boolean value.
  Future<void> setBool({
    required String key,
    required bool value,
  }) async =>
      await _delegate.globalAttributesSetBool(key: key, value: value);

  // Lists are currently set to private will be handled after first release
/*
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
*/

  /// Sets multiple attributes.
  ///
  /// [attributes] - Key-value pairs to set.
  ///
  /// Example:
  /// ```dart
  /// await attrs.setAll(
  ///   attributes: MutableAttributes({
  ///     'app.version': '2.0.0',
  ///     'app.build': 1234,
  ///   }),
  /// );
  /// ```
  Future<void> setAll(
          {required MutableAttributes attributes}) async =>
      await _delegate.globalAttributesSetAll(attributes: attributes);
}
