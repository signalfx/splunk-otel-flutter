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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_example/test_actions_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ///* Set through --dart-define for flutter run
  /// --dart-define=REALM=your_realm
  /// --dart-define=RUM_ACCESS_TOKEN=your_token
  const String realm = String.fromEnvironment('REALM');
  const String rumAccessToken = String.fromEnvironment('RUM_ACCESS_TOKEN');

  await SplunkOtelFlutter.instance.install(
    agentConfiguration: AgentConfiguration(
      endpointConfiguration: EndpointConfiguration.forRum(
        realm: realm,
        rumAccessToken: rumAccessToken,
      ),
      appName: 'Splunk 0tel Example App',
      deploymentEnvironment: 'dev',
      enableDebugLogging: true,
      globalAttributes: MutableAttributes(
        attributes: {
          "boolKey": MutableAttributeBool(value: true),
          "stringKey": MutableAttributeString(value: "testVal"),
          "intKey": MutableAttributeInt(value: 1),
          "doubleKey": MutableAttributeDouble(value: 1.3),
        },
      ),
    ),
    moduleConfigurations: [
      NavigationModuleConfiguration(
        isEnabled: true,
        isAutomatedTrackingEnabled: false,
      ),
      SlowRenderingModuleConfiguration(isEnabled: true),
      AnrModuleConfiguration(isEnabled: true),
      InteractionsModuleConfiguration(isEnabled: false),
      SlowRenderingModuleConfiguration(isEnabled: false, interval: const Duration(seconds: 1)),
      AnrModuleConfiguration(isEnabled: false),
      CrashReportsModuleConfiguration(isEnabled: false)
    ],
  );

  await SplunkOtelFlutter.instance.sessionReplay.start();

  Future<void>.delayed(const Duration(seconds: 1)).then((_) async {
    final sessionId = await SplunkOtelFlutter.instance.session.state.getId();

    debugPrint('-------------');
    debugPrint('Session id: $sessionId');
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _channel = MethodChannel('com.splunk.rum.flutter.example');

  late final List<TestAction> _actions = [
    TestAction(
      title: 'Simulate Crash',
      description: 'Crashes the app',
      category: TestCategory.crashes,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTap: simulateCrash,
    ),
    TestAction(
      title: 'Simulate Navigation',
      description: 'Mock navigate to a random non existing screen',
      category: TestCategory.navigation,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTap: simulateNavigation,
    ),
    TestAction(
      title: 'Track custom event',
      description: 'track custom event',
      category: TestCategory.customTracking,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTap: customTrackingTrackEvent,
    ),
    TestAction(
      title: 'Track workflow',
      description: 'track workflow',
      category: TestCategory.customTracking,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTap: customTrackingTrackWorkflow,
    ),
    TestAction(
      title: 'Track error',
      description: 'track error',
      category: TestCategory.customTracking,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTap: customTrackingTrackError,
    ),
    TestAction(
      title: 'Simulate Slow Render',
      description: 'Simulates an slow render',
      category: TestCategory.performance,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTap: simulateSlowRender,
    ),
    TestAction(
      title: 'Simulate Frozen Render',
      description: 'Simulates an frozen render',
      category: TestCategory.performance,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTap: simulateFrozenRender,
    ),
    TestAction(
      title: 'Trigger ANR',
      description: 'Simulates an ANR',
      category: TestCategory.performance,
      platforms: {MobilePlatform.android},
      onTap: triggerANR,
    ),
    TestAction(
      title: 'OkHttp GET',
      description: 'Network interception via OkHttp',
      category: TestCategory.network,
      platforms: {MobilePlatform.android},
      onTap: testOkHttp,
    ),
    TestAction(
      title: 'HttpURLConnection GET',
      description: 'Network interception via HttpURLConnection',
      category: TestCategory.network,
      platforms: {MobilePlatform.android},
      onTap: testHttpUrlConnection,
    ),
    TestAction(
      title: 'URLSession GET',
      description: 'Network interception via iOS URLSession',
      category: TestCategory.network,
      platforms: {MobilePlatform.ios},
      onTap: testiOSURLSessionGet,
    ),
  ];

  @override
  void initState() {
    super.initState();

    //exercisePublicApiWithAsserts();
    /*
    // session replay - sensitivity ignored
    SplunkOtelFlutter.instance.sessionReplay.start();
    SplunkOtelFlutter.instance.sessionReplay.stop();
    SplunkOtelFlutter.instance.sessionReplay.state.getStatus();
    SplunkOtelFlutter.instance.sessionReplay.state.getRenderingMode();
    SplunkOtelFlutter.instance.sessionReplay.preferences.getRenderingMode();
    SplunkOtelFlutter.instance.sessionReplay.preferences.setRenderingMode(
      renderingMode: RenderingMode.native,
    );
    SplunkOtelFlutter.instance.sessionReplay.recordingMask.getRecordingMask();
    SplunkOtelFlutter.instance.sessionReplay.recordingMask.setRecordingMask(
      recordingMask: RecordingMaskList(elements: []),
    );

    // state
    SplunkOtelFlutter.instance.state.getAppName();
    SplunkOtelFlutter.instance.state.getAppVersion();
    SplunkOtelFlutter.instance.state.getStatus();
    SplunkOtelFlutter.instance.state.getEndpointConfiguration();
    SplunkOtelFlutter.instance.state.getDeploymentEnvironment();
    SplunkOtelFlutter.instance.state.getIsDebugLoggingEnabled();
    SplunkOtelFlutter.instance.state.getInstrumentedProcessName();
    SplunkOtelFlutter.instance.state.getDeferredUntilForeground();

    // preferences
    SplunkOtelFlutter.instance.preferences.getEndpointConfiguration();

    // session
    SplunkOtelFlutter.instance.session.state.getId();
    SplunkOtelFlutter.instance.session.state.getSamplingRate();

    // user
    SplunkOtelFlutter.instance.user.state.getTrackingMode();
    SplunkOtelFlutter.instance.user.preferences.getTrackingMode();
    SplunkOtelFlutter.instance.user.preferences.setTrackingMode(
      userTrackingMode: UserTrackingMode.noTracking,
    );

    // global attributes
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesGet(
      key: "my_key",
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesGetAll();
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesRemove(
      key: "old_key",
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesRemoveAll();
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesContains(
      key: "existing_key",
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetString(
      key: "user_name",
      value: "Alice",
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetInt(
      key: "user_id",
      value: 123,
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetDouble(
      key: "app_version",
      value: 1.5,
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetBool(
      key: "is_logged_in",
      value: true,
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetStringList(
      key: "tags",
      value: ["mobile", "flutter"],
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetIntList(
      key: "permissions",
      value: [1, 2, 3],
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetDoubleList(
      key: "scores",
      value: [9.5, 8.0],
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetBoolList(
      key: "features",
      value: [true, false],
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetAll(
      key: "bulk_data",
      attributes: MutableAttributes(
        attributes: {
          "attr1": MutableAttributeString(value: "val1"),
          "attr2": MutableAttributeInt(value: 100),
        },
      ),
    );
*/
    // open telemetry ignored
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo);

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Splunk OTel SDK Test App')),
        body: TestActionsWidget(actions: _actions),
      ),
    );
  }

  // Both platforms

  Future<void> simulateCrash() async {
    try {
      await _channel.invokeMethod('simulateCrash');
    } catch (e) {
      debugPrint("simulate crash test failed: $e");
    }
  }

  Future<void> simulateNavigation() async {
    final random = Random();
    final screenNumber = random.nextInt(1000) + 1; // generates 1–1000
    final screenName = 'mockScreen$screenNumber';

    SplunkOtelFlutter.instance.navigation.track(screenName: screenName);
  }

  Future<void> simulateSlowRender() async {
    try {
      await _channel.invokeMethod('simulateSlowRender');
    } catch (e) {
      debugPrint("Failed to simulate slow render: $e");
    }
  }

  Future<void> customTrackingTrackEvent() async {
    final random = Random();
    final eventNumber = random.nextInt(1000) + 1; // generates 1–1000

    SplunkOtelFlutter.instance.customTracking.trackCustomEvent(
      name: "test custom event tracking $eventNumber",
      attributes: MutableAttributes(
        attributes: {
          "intKeyTrackEvent": MutableAttributeInt(value: 5),
          "stringKeyTrackEvent": MutableAttributeString(value: "myVal"),
        },
      ),
    );
  }

  Future<void> customTrackingTrackWorkflow() async {
    SplunkOtelFlutter.instance.customTracking.trackWorkflow(
      workflowName: "Workflow test",
    );
  }

  Future<void> customTrackingTrackError() async {
    throw "TODO";
  }

  Future<void> simulateFrozenRender() async {
    try {
      await _channel.invokeMethod('simulateFrozenRender');
    } catch (e) {
      debugPrint("Failed to simulate frozen render: $e");
    }
  }

  // Android

  Future<void> triggerANR() async {
    try {
      await _channel.invokeMethod('simulateANR');
    } catch (e) {
      debugPrint("Failed to simulate ANR: $e");
    }
  }

  Future<void> testOkHttp() async {
    try {
      await _channel.invokeMethod('testOkHttpGet');
    } catch (e) {
      debugPrint("OkHttp test failed: $e");
    }
  }

  Future<void> testHttpUrlConnection() async {
    try {
      await _channel.invokeMethod('testHttpUrlConnectionGet');
    } catch (e) {
      debugPrint("HttpURLConnection test failed: $e");
    }
  }

  // iOS

  Future<void> testiOSURLSessionGet() async {
    try {
      await _channel.invokeMethod('testURLSessionGet');
    } catch (e) {
      debugPrint("URLSession test failed: $e");
    }
  }

  // ---- Public API smoke test with set->get->assert checks ----

  Future<void> exercisePublicApiWithAsserts() async {
    final sdk = SplunkOtelFlutter.instance;

    // Helpers
    T castAttr<T extends MutableAttributeValue?>(MutableAttributeValue? v) {
      assert(v is T, 'Expected ${T.toString()}, got ${v.runtimeType}');
      return v as T;
    }

    try {
      // ========= Session / SessionState =========
      final sessionId = await sdk.session.state.getId();
      final samplingRate = await sdk.session.state.getSamplingRate();
      assert(sessionId.isNotEmpty, 'Session id should not be empty');
      assert(
        samplingRate >= 0 && samplingRate <= 1,
        'Sampling rate should be in [0,1]',
      );

      // ========= State =========
      final appName = await sdk.state.getAppName();
      await sdk.state
          .getAppVersion(); // Smoke test - just verify it doesn't throw
      final status = await sdk.state.getStatus();
      await sdk.state
          .getEndpointConfiguration(); // Smoke test - just verify it doesn't throw
      final env = await sdk.state.getDeploymentEnvironment();
      final debugEnabled = await sdk.state.getIsDebugLoggingEnabled();
      await sdk.state
          .getInstrumentedProcessName(); // Smoke test - just verify it doesn't throw
      await sdk.state
          .getDeferredUntilForeground(); // Smoke test - just verify it doesn't throw

      assert(appName.isNotEmpty, 'App name should not be empty');
      assert(env.isNotEmpty, 'Deployment environment should not be empty');
      assert(
        status != Status.notInstalled,
        'Agent should be installed for this test',
      );
      assert(debugEnabled == true, 'Debug logging should be enabled (true)');

      // ========= User / UserState & Preferences =========
      final trackingFromState = await sdk.user.state.getTrackingMode();
      final trackingFromPrefs = await sdk.user.preferences.getTrackingMode();
      final trackingModeToSet = trackingFromPrefs ?? trackingFromState;
      await sdk.user.preferences.setTrackingMode(
        userTrackingMode: trackingModeToSet,
      );
      final trackingAfter = await sdk.user.preferences.getTrackingMode();
      assert(
        trackingAfter == trackingModeToSet,
        'User tracking mode did not persist',
      );

      // ========= SessionReplay: start/stop, state & preferences =========
      final srModeBefore = await sdk.sessionReplay.state.getRenderingMode();
      final srStatusBefore = await sdk.sessionReplay.state.getStatus();
      assert(
        srStatusBefore != SessionReplayStatus.internalError,
        'Session Replay should not be in internalError',
      );

      await sdk.sessionReplay.preferences.setRenderingMode(
        renderingMode: srModeBefore,
      );
      final srModePref = await sdk.sessionReplay.preferences.getRenderingMode();
      assert(
        srModePref == srModeBefore,
        'SR prefs mode should equal state mode after set',
      );

      // Recording mask: set -> get -> assert -> restore
      final originalMask = await sdk.sessionReplay.recordingMask
          .getRecordingMask();
      final tempMask = RecordingMaskList(
        elements: [
          RecordingMaskElement(
            rect: const Rect.fromLTWH(10, 10, 120, 40),
            type: RecordingMaskType.erasing,
          ),
          RecordingMaskElement(
            rect: const Rect.fromLTWH(20, 70, 200, 60),
            type: RecordingMaskType.covering,
          ),
        ],
      );
      await sdk.sessionReplay.recordingMask.setRecordingMask(
        recordingMask: tempMask,
      );
      final maskAfterSet = await sdk.sessionReplay.recordingMask
          .getRecordingMask();
      assert(
        maskAfterSet != null,
        'Recording mask should not be null after set',
      );
      assert(
        maskAfterSet!.elements.length == tempMask.elements.length,
        'Recording mask element count mismatch',
      );
      // Spot-check first element equivalence
      final a = maskAfterSet!.elements.first;
      final b = tempMask.elements.first;
      assert(a.type == b.type, 'Recording mask first element type mismatch');
      assert(
        a.rect.left == b.rect.left &&
            a.rect.top == b.rect.top &&
            a.rect.width == b.rect.width &&
            a.rect.height == b.rect.height,
        'Recording mask first element rect mismatch',
      );

      // Stop/start roundtrip
      await sdk.sessionReplay.stop();
      final srStatusStopped = await sdk.sessionReplay.state.getStatus();
      assert(
        srStatusStopped == SessionReplayStatus.stopped ||
            srStatusStopped == SessionReplayStatus.notStarted,
        'SR should report stopped/notStarted after stop()',
      );
      await sdk.sessionReplay.start();
      final srStatusStarted = await sdk.sessionReplay.state.getStatus();
      assert(
        srStatusStarted == SessionReplayStatus.isRecording ||
            srStatusStarted ==
                SessionReplayStatus
                    .notStarted, // allow platforms that don't autostart
        'SR should be recording or notStarted after start()',
      );

      // Restore previous mask if one existed
      if (originalMask != null) {
        await sdk.sessionReplay.recordingMask.setRecordingMask(
          recordingMask: originalMask,
        );
        final restored = await sdk.sessionReplay.recordingMask
            .getRecordingMask();
        assert(
          restored!.elements.length == originalMask.elements.length,
          'Original mask was not restored',
        );
      }

      // ========= GlobalAttributes (all getters/setters with assertions) =========
      // Scalars
      await sdk.globalAttributes.setString(key: 'ga_string', value: 'hello');
      final gaString = castAttr<MutableAttributeString>(
        await sdk.globalAttributes.get(key: 'ga_string'),
      );
      assert(gaString.value == 'hello', 'ga_string roundtrip failed');

      await sdk.globalAttributes.setInt(key: 'ga_int', value: 42);
      final gaInt = castAttr<MutableAttributeInt>(
        await sdk.globalAttributes.get(key: 'ga_int'),
      );
      assert(gaInt.value == 42, 'ga_int roundtrip failed');

      final gaDouble = castAttr<MutableAttributeDouble>(
        await sdk.globalAttributes.get(key: 'ga_double'),
      );
      assert(
        (gaDouble.value - 3.1415).abs() < 1e-9,
        'ga_double roundtrip failed',
      );

      await sdk.globalAttributes.setBool(key: 'ga_bool', value: true);
      final gaBool = castAttr<MutableAttributeBool>(
        await sdk.globalAttributes.get(key: 'ga_bool'),
      );
      assert(gaBool.value == true, 'ga_bool roundtrip failed');

      // contains()
      final hasGaString = await sdk.globalAttributes.contains(key: 'ga_string');
      assert(hasGaString == true, 'contains(ga_string) should be true');

      // getAll()
      final allBefore = await sdk.globalAttributes.getAll();
      assert(allBefore.attributes.isNotEmpty, 'getAll() should contain items');
      assert(
        allBefore.attributes.keys.contains('ga_int'),
        'getAll() should include ga_int',
      );

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

      // Check a few bundle keys came through
      final bBool = castAttr<MutableAttributeBool>(
        await sdk.globalAttributes.get(key: 'bundle_bool'),
      );
      final bStr = castAttr<MutableAttributeString>(
        await sdk.globalAttributes.get(key: 'bundle_string'),
      );
      //TODO resolve issue with empty array set and get both Android iOS
      assert(bBool.value == false, 'bundle_bool not persisted');

      assert(bStr.value == 'pack', 'bundle_string not persisted');

      // remove() then contains()
      await sdk.globalAttributes.remove(key: 'ga_string');
      final hasAfterRemove = await sdk.globalAttributes.contains(
        key: 'ga_string',
      );
      assert(hasAfterRemove == false, 'ga_string should be removed');

      // removeAll() then getAll()
      await sdk.globalAttributes.removeAll();
      final allAfter = await sdk.globalAttributes.getAll();
      assert(
        allAfter.attributes.isEmpty,
        'removeAll() should leave no attributes',
      );

      // Final log to make it easy to see result in console
      // ignore: avoid_print
      print('✅ SplunkOtelFlutter public API smoke test with asserts completed');
    } catch (e, st) {
      // ignore: avoid_print
      print('⚠️ SplunkOtelFlutter API assert test caught error: $e\n$st');
    }
  }
}
