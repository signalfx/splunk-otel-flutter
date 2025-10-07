import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SplunkOtelFlutter.instance.install(
    agentConfiguration: AgentConfiguration(
      endpoint: EndpointConfiguration(),
      appName: 'Splunk Root Example App',
      deploymentEnvironment: 'dev',
    ),
    moduleConfigurations: [
      NavigationModuleConfiguration(isEnabled: true),
      SlowRenderingModuleConfiguration(isEnabled: false),
    ],
  );

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
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
