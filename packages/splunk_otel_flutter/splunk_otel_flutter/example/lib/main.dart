import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ///* Set through --dart-define for flutter run
  /// --dart-define=REALM=your_realm
  /// --dart-define=RUM_ACCESS_TOKEN=your_token
  const String realm = String.fromEnvironment('REALM');
  const String rumAccessToken = String.fromEnvironment('RUM_ACCESS_TOKEN');

  await SplunkOtelFlutter.instance.install(
    agentConfiguration: AgentConfiguration(
      endpoint: const EndpointConfiguration(
        realm: realm,
        rumAccessToken: rumAccessToken,
      ),
      appName: 'Splunk 0tel Example App',
      deploymentEnvironment: 'dev',
      enableDebugLogging: true,
      globalAttributes: {
        "keyString": "value",
        "keyInt": 5,
        "keyDouble": 5.0,
        "keyBool": true,
        "keyArray": [1,2,"test","2"]
      },
    ),
    moduleConfigurations: [
      NavigationModuleConfiguration(isEnabled: true),
      SlowRenderingModuleConfiguration(isEnabled: false),
    ],
  );

  await SplunkOtelFlutter.instance.startSessionReplay();

  final sessionId = await SplunkOtelFlutter.instance.getSessionId();

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
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: const Center(
          child: Text('Running on:'),
        ),
      ),
    );
  }
}
