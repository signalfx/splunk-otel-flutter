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
      appVersion: '1.0.0',
      endpoint: EndpointConfiguration(
        realm: realm,
        rumAccessToken: rumAccessToken,
      ),
      appName: 'Splunk Root Example App',
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

  await SplunkOtelFlutter.instance.sessionReplay.start();

  final sessionId = await SplunkOtelFlutter.instance.session.state.getId();

  debugPrint('-------------');
  debugPrint('Session id: $sessionId');

  runApp(const SplunkRootExampleApp());
}

class SplunkRootExampleApp extends StatelessWidget {
  const SplunkRootExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splunk Root Example App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Splunk Root Example App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
    );
  }
}
