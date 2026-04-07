import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/welcome_screen.dart';
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ///* Set through --dart-define for flutter run
  /// --dart-define=REALM=your_realm
  /// --dart-define=RUM_ACCESS_TOKEN=your_token
  const String realm = String.fromEnvironment('REALM');
  const String rumAccessToken = String.fromEnvironment('RUM_ACCESS_TOKEN');

  // Install without endpoint configuration (deferred credentials).
  final stopwatch = Stopwatch()..start();

  await SplunkRum.instance.install(
    agentConfiguration: AgentConfiguration(
      appName: "Flutter Splunk cinema demo",
      deploymentEnvironment: 'test',
    ),
  );

  stopwatch.stop();
  debugPrint('=============');
  debugPrint('SplunkRum.install() took: ${stopwatch.elapsedMilliseconds} ms');
  debugPrint('=============');

  final sessionReplay = SplunkSessionReplay.instance;

  await sessionReplay.start();
  debugPrint('Session replay started');

  final status = await sessionReplay.getStatus();
  debugPrint('Session replay status: $status');

  await sessionReplay.setRecordingMask(
    recordingMask: RecordingMaskList(
      elements: [
        RecordingMaskElement(
          rect: const Rect.fromLTWH(0, 0, 200, 100),
          type: RecordingMaskType.covering,
        ),
        RecordingMaskElement(
          rect: const Rect.fromLTWH(50, 50, 100, 50),
          type: RecordingMaskType.erasing,
        ),
      ],
    ),
  );
  debugPrint('Recording mask set');

  final mask = await sessionReplay.getRecordingMask();
  debugPrint('Recording mask elements: ${mask?.elements.length ?? 0}');

  // Set endpoint configuration after install.
  await SplunkRum.instance.preferences.setEndpointConfiguration(
    endpointConfiguration: EndpointConfiguration.forRum(
      realm: realm,
      rumAccessToken: rumAccessToken,
    ),
  );
  debugPrint('Endpoint configuration set after install.');

  Future<void>.delayed(const Duration(seconds: 1)).then((_) async {
    final sessionId = await SplunkRum.instance.session.state.getId();

    debugPrint('-------------');
    debugPrint('Session id: $sessionId');
  });

  runApp(const DemoApp());
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Splunk Flutter demo app - SmartCinema',
      home: const WelcomeScreen(),
      navigatorObservers: [routeObserver],
    );
  }
}
