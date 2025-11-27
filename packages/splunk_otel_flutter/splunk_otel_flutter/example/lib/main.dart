import 'dart:async';
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
      endpoint: EndpointConfiguration.forRum(
        realm: realm,
        rumAccessToken: rumAccessToken,
      ),
      appName: 'Splunk 0tel Example App',
      deploymentEnvironment: 'dev',
      enableDebugLogging: true,
      session: SessionConfiguration(samplingRate: 1),
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
      SlowRenderingModuleConfiguration(isEnabled: true),
      NavigationModuleConfiguration(isEnabled: true),
      CrashReportsModuleConfiguration(isEnabled: true),
      InteractionsModuleConfiguration(isEnabled: true),
      NetworkMonitorModuleConfiguration(isEnabled: true),
      AnrModuleConfiguration(isEnabled: true),
      HttpUrlModuleConfiguration(
        isEnabled: true,
        capturedRequestHeaders: ["Content-Type", "Accept"],
        capturedResponseHeaders: ["Server", "Content-Type", "Content-Length"],
      ),
      OkHttp3AutoModuleConfiguration(
        isEnabled: true,
        capturedRequestHeaders: ["Content-Type", "Accept"],
        capturedResponseHeaders: ["Server", "Content-Type", "Content-Length"],
      ),
      NetworkInstrumentationModuleConfiguration(
        isEnabled: true,
        ignoreURLs: [
          RegularExpression(
            pattern: r"^https:\/\/example\.com\/.*$",
            options: [RegexOption.caseInsensitive],
          ),
        ],
      ),
    ],
  );

  await SplunkOtelFlutter.instance.sessionReplay.start();

  // not instantly available
  Future.delayed(const Duration(seconds: 1), () async {
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
    SplunkOtelFlutter.instance.customTracking.trackCustomEvent(
      name: "test custom workflow",
      attributes: MutableAttributes(
        attributes: {
          "intKeyWorkflow": MutableAttributeInt(value: 5),
          "stringKeyWorkflow": MutableAttributeString(value: "myVal"),
        },
      ),
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
}

class TestException extends Error {}
