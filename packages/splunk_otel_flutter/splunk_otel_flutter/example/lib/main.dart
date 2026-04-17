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
import 'package:splunk_otel_flutter_example/webview_screen.dart';
import 'package:splunk_otel_flutter_example/browser_launcher_screen.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ///* Set through --dart-define for flutter run
  /// --dart-define=REALM=your_realm
  /// --dart-define=RUM_ACCESS_TOKEN=your_token
  const String realm = String.fromEnvironment('REALM');
  const String rumAccessToken = String.fromEnvironment('RUM_ACCESS_TOKEN');

  // Measure install duration
  final stopwatch = Stopwatch()..start();

  await SplunkRum.instance.install(
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
        isAutomatedTrackingEnabled: true,
      ),
      SlowRenderingModuleConfiguration(isEnabled: true),
      AnrModuleConfiguration(isEnabled: true),
      InteractionsModuleConfiguration(isEnabled: true),
      SlowRenderingModuleConfiguration(
        isEnabled: true,
        interval: const Duration(seconds: 1),
      ),
      AnrModuleConfiguration(isEnabled: true),
      CrashReportsModuleConfiguration(isEnabled: true),
      ApplicationLifecycleModuleConfiguration(isEnabled: false),
    ],
  );

  stopwatch.stop();
  debugPrint('=============');
  debugPrint('SplunkRum.install() took: ${stopwatch.elapsedMilliseconds} ms');
  debugPrint('=============');

  final sessionId = await SplunkRum.instance.session.state.getId();

  debugPrint('-------------');
  debugPrint('Session id: $sessionId');

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
      title: 'Open WebView',
      description: 'Navigate to WebView screen to test web content',
      category: TestCategory.navigation,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTapWithContext: openWebView,
    ),
    TestAction(
      title: 'Browser Options',
      description: 'Choose between Custom Tabs, Safari VC, or External Browser',
      category: TestCategory.navigation,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTapWithContext: openBrowserOptions,
    ),
    TestAction(
      title: 'In-App Browser',
      description: 'Custom Tabs (Android) / Safari VC (iOS)',
      category: TestCategory.navigation,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTap: launchInAppBrowser,
    ),
    TestAction(
      title: 'External Browser',
      description: 'Opens in default system browser',
      category: TestCategory.navigation,
      platforms: {MobilePlatform.android, MobilePlatform.ios},
      onTap: launchExternalBrowser,
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
    // exercisePublicApiWithAsserts();
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

    SplunkRum.instance.navigation.track(screenName: screenName);
  }

  Future<void> openWebView(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const WebViewScreen()),
    );
  }

  Future<void> openBrowserOptions(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const BrowserLauncherScreen(),
      ),
    );
  }

  Future<void> launchInAppBrowser() async {
    final url = Uri.parse('https://www.splunk.com');
    try {
      // Uses Custom Tabs on Android and SFSafariViewController on iOS
      await launchUrl(url, mode: LaunchMode.inAppWebView);
      debugPrint('Launched in-app browser for: $url');
    } catch (e) {
      debugPrint('Failed to launch in-app browser: $e');
    }
  }

  Future<void> launchExternalBrowser() async {
    final url = Uri.parse('https://www.splunk.com');
    try {
      // Opens in external browser app
      await launchUrl(url, mode: LaunchMode.externalApplication);
      debugPrint('Launched external browser for: $url');
    } catch (e) {
      debugPrint('Failed to launch external browser: $e');
    }
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

    SplunkRum.instance.customTracking.trackCustomEvent(
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
    final workflow = await SplunkRum.instance.customTracking.startWorkflow(
      name: "Workflow test",
    );
    // Simulate some work
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await workflow.end();
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
    final sdk = SplunkRum.instance;

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
      print('✅ SplunkRum public API smoke test with asserts completed');
    } catch (e, st) {
      // ignore: avoid_print
      print('⚠️ SplunkRum API assert test caught error: $e\n$st');
    }
  }
}
