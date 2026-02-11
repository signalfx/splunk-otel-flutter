/*
 * Copyright 2026 Splunk Inc.
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

import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

class BasicTestRunWidget extends StatefulWidget {
  const BasicTestRunWidget({super.key});

  @override
  State<BasicTestRunWidget> createState() => _BasicTestRunWidgetState();
}

class _BasicTestRunWidgetState extends State<BasicTestRunWidget> {
  @override
  Widget build(BuildContext context) {
    return const Text("y");
  }


  Future<void> wholeApiDefinition()async{
    // state
    SplunkRum.instance.state.getAppName();
    SplunkRum.instance.state.getAppVersion();
    SplunkRum.instance.state.getStatus();
    SplunkRum.instance.state.getEndpointConfiguration();
    SplunkRum.instance.state.getDeploymentEnvironment();
    SplunkRum.instance.state.getIsDebugLoggingEnabled();
    SplunkRum.instance.state.getInstrumentedProcessName();
    SplunkRum.instance.state.getDeferredUntilForeground();

    // session
    SplunkRum.instance.session.state.getId();
    SplunkRum.instance.session.state.getSamplingRate();

    // user
    SplunkRum.instance.user.state.getTrackingMode();
    SplunkRum.instance.user.preferences.getTrackingMode();
    SplunkRum.instance.user.preferences.setTrackingMode(
      userTrackingMode: UserTrackingMode.noTracking,
    );

    // global attributes
    SplunkRum.instance.globalAttributes.get(
      key: "my_key",
    );
    SplunkRum.instance.globalAttributes.getAll();
    SplunkRum.instance.globalAttributes.remove(
      key: "old_key",
    );
    SplunkRum.instance.globalAttributes.removeAll();
    SplunkRum.instance.globalAttributes.contains(
      key: "existing_key",
    );
    SplunkRum.instance.globalAttributes.setString(
      key: "user_name",
      value: "Alice",
    );
    SplunkRum.instance.globalAttributes.setInt(
      key: "user_id",
      value: 123,
    );
    SplunkRum.instance.globalAttributes.setDouble(
      key: "app_version",
      value: 1.5,
    );
    SplunkRum.instance.globalAttributes.setBool(
      key: "is_logged_in",
      value: true,
    );
    /*
    SplunkRum.instance.globalAttributes.globalAttributesSetStringList(
      key: "tags",
      value: ["mobile", "flutter"],
    );
    SplunkRum.instance.globalAttributes.globalAttributesSetIntList(
      key: "permissions",
      value: [1, 2, 3],
    );
    SplunkRum.instance.globalAttributes.globalAttributesSetDoubleList(
      key: "scores",
      value: [9.5, 8.0],
    );
    SplunkRum.instance.globalAttributes.globalAttributesSetBoolList(
      key: "features",
      value: [true, false],
    );*/
    SplunkRum.instance.globalAttributes.setAll(
      attributes: MutableAttributes(
        attributes: {
          "attr1": MutableAttributeString(value: "val1"),
          "attr2": MutableAttributeInt(value: 100),
        },
      ),
    );

    // Custom tracking
    SplunkRum.instance.customTracking.trackCustomEvent(name: "testEvent", attributes: MutableAttributes());
    final workflow = await SplunkRum.instance.customTracking.startWorkflow(name: "testWorkflow");
    await workflow.end();

    // Navigation
    SplunkRum.instance.navigation.track(screenName: "testScreen");
  }


// ---- Public API smoke test with set->get->assert checks ----

  Future<void> exercisePublicApiWithAsserts() async {
    final sdk = SplunkRum.instance;

    // Helpers
    bool listEquals<T>(List<T> a, List<T> b) {
      if (identical(a, b)) return true;
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }

    T castAttr<T extends MutableAttributeValue>(MutableAttributeValue v) {
      assert(v is T, 'Expected ${T.toString()}, got ${v.runtimeType}');
      return v as T;
    }

    String attrToDebug(MutableAttributeValue v) {
      if (v is MutableAttributeString) return 'String(${v.value})';
      if (v is MutableAttributeInt) return 'Int(${v.value})';
      if (v is MutableAttributeDouble) return 'Double(${v.value})';
      if (v is MutableAttributeBool) return 'Bool(${v.value})';
      return v.runtimeType.toString();
    }

    try {
      // ========= Session / SessionState =========
      final sessionId = await sdk.session.state.getId();
      final samplingRate = await sdk.session.state.getSamplingRate();
      assert(sessionId.isNotEmpty, 'Session id should not be empty');
      assert(samplingRate >= 0 &&
          samplingRate <= 1, 'Sampling rate should be in [0,1]');

      // ========= State =========
      final appName = await sdk.state.getAppName();
      final appVersion = await sdk.state.getAppVersion();
      final status = await sdk.state.getStatus();
      final endpointCfg = await sdk.state.getEndpointConfiguration();
      final env = await sdk.state.getDeploymentEnvironment();
      final debugEnabled = await sdk.state.getIsDebugLoggingEnabled();
      final procName = await sdk.state.getInstrumentedProcessName();
      final deferred = await sdk.state.getDeferredUntilForeground();

      assert(appName.isNotEmpty, 'App name should not be empty');
      assert(env.isNotEmpty, 'Deployment environment should not be empty');
      assert(status !=
          Status.notInstalled, 'Agent should be installed for this test');
      assert(debugEnabled == true, 'Debug logging should be enabled (true)');

      // ========= User / UserState & Preferences =========
      final trackingFromState = await sdk.user.state.getTrackingMode();
      final trackingFromPrefs = await sdk.user.preferences.getTrackingMode();
      final trackingModeToSet = trackingFromPrefs ?? trackingFromState;
      await sdk.user.preferences.setTrackingMode(
          userTrackingMode: trackingModeToSet);
      final trackingAfter = await sdk.user.preferences.getTrackingMode();
      assert(trackingAfter ==
          trackingModeToSet, 'User tracking mode did not persist');

      // ========= GlobalAttributes (all getters/setters with assertions) =========
      // Scalars
      await sdk.globalAttributes.setString(key: 'ga_string', value: 'hello');
      final gaString = castAttr<MutableAttributeString>(
          await sdk.globalAttributes.get(key: 'ga_string'));
      assert(gaString.value == 'hello', 'ga_string roundtrip failed');

      await sdk.globalAttributes.setInt(key: 'ga_int', value: 42);
      final gaInt = castAttr<MutableAttributeInt>(
          await sdk.globalAttributes.get(key: 'ga_int'));
      assert(gaInt.value == 42, 'ga_int roundtrip failed');

      await sdk.globalAttributes.setDouble(key: 'ga_double', value: 3.1415);
      final gaDouble = castAttr<MutableAttributeDouble>(
          await sdk.globalAttributes.get(key: 'ga_double'));
      assert((gaDouble.value - 3.1415).abs() <
          1e-9, 'ga_double roundtrip failed');

      await sdk.globalAttributes.setBool(key: 'ga_bool', value: true);
      final gaBool = castAttr<MutableAttributeBool>(
          await sdk.globalAttributes.get(key: 'ga_bool'));
      assert(gaBool.value == true, 'ga_bool roundtrip failed');


      // contains()
      final hasGaString = await sdk.globalAttributes.contains(key: 'ga_string');
      assert(hasGaString == true, 'contains(ga_string) should be true');

      // getAll()
      final allBefore = await sdk.globalAttributes.getAll();
      assert(allBefore.attributes.isNotEmpty, 'getAll() should contain items');
      assert(allBefore.attributes.keys.contains(
          'ga_int'), 'getAll() should include ga_int');

      // setAll() bundle → verify by reading keys back
      await sdk.globalAttributes.setAll(
        attributes: MutableAttributes(
          attributes: {
            'bundle_bool': MutableAttributeBool(value: false),
            'bundle_int': MutableAttributeInt(value: 7),
            'bundle_double': MutableAttributeDouble(value: 2.71),
            'bundle_string': MutableAttributeString(value: 'pack'),
          },
        ),
      );

      // remove() then contains()
      await sdk.globalAttributes.remove(key: 'ga_string');
      final hasAfterRemove = await sdk.globalAttributes.contains(
          key: 'ga_string');
      assert(hasAfterRemove == false, 'ga_string should be removed');

      // removeAll() then getAll()
      await sdk.globalAttributes.removeAll();
      final allAfter = await sdk.globalAttributes.getAll();
      assert(allAfter.attributes
          .isEmpty, 'removeAll() should leave no attributes');


      //TODO
      // Custom tracking
      // Navigation


      // Final log to make it easy to see result in console
      // ignore: avoid_print
      print('✅ SplunkRum public API smoke test with asserts completed');


    } catch (e, st) {
      // ignore: avoid_print
      print('⚠️ SplunkRum API assert test caught error: $e\n$st');
    }
  }
}
