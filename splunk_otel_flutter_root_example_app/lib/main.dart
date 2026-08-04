import 'dart:io';

import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/welcome_screen.dart';
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ///* Set through --dart-define for flutter run
  /// --dart-define=REALM=your_realm
  /// --dart-define=RUM_ACCESS_TOKEN=your_token
  const String realm = String.fromEnvironment('REALM');
  const String rumAccessToken = String.fromEnvironment('RUM_ACCESS_TOKEN');

  // Simulation hook for the iOS background-launch cold-start issue.
  //
  // The native SplunkAgent anchors a cold start at the real (BSD) process-start
  // time and ends it when the SDK observes activation at install. On a real iOS
  // background launch the process starts long before the SDK installs, so the
  // whole gap is reported as cold-start latency (see Confluence: "iOS App Start
  // Measurement for React Native Background Launches", section 3.2).
  //
  // The Simulator does not cold-launch a terminated app from a silent push, so we
  // reproduce the SAME anchoring problem deterministically by delaying install():
  // the process starts at T0 but the SDK only installs T0 + INSTALL_DELAY_SECONDS.
  //   flutter run --dart-define=INSTALL_DELAY_SECONDS=25 ...
  const int installDelaySeconds = int.fromEnvironment('INSTALL_DELAY_SECONDS');
  if (installDelaySeconds > 0) {
    debugPrint(
      '[BG-LAUNCH-PROBE] Delaying SplunkRum.install() by '
      '$installDelaySeconds s to simulate a late SDK init after an early '
      'process start.',
    );
    await Future<void>.delayed(Duration(seconds: installDelaySeconds));
  }

  // Install without endpoint configuration (deferred credentials).
  final stopwatch = Stopwatch()..start();

  await SplunkRum.instance.install(
    agentConfiguration: AgentConfiguration(
      appName: "Flutter Splunk cinema demo",
      deploymentEnvironment: 'test',
      // Surfaces the native SDK's AppStart span (start.type + duration) in the
      // device logs, which is used to observe the background-launch cold-start
      // simulation. See tool/simulate_background_launch.sh.
      enableDebugLogging: true,
    ),
    moduleConfigurations: [
      SessionReplayModuleConfiguration(samplingRate: 1.0),
      // Network header capture is configured per-platform: NetworkInstrumentation
      // for iOS (URLSession) and HttpUrl/OkHttp3Auto for Android. Each platform
      // ignores configurations that don't apply to it.
      NetworkInstrumentationModuleConfiguration(
        isEnabled: true,
        ignoreURLs: [
          RegularExpression(
            pattern: r'.*\.example\.com',
            options: const [RegexOption.caseInsensitive],
          ),
          RegularExpression(pattern: r'^https?://localhost(:\d+)?(/.*)?$'),
        ],
        capturedRequestHeaders: const [
          'Accept',
          'Content-Type',
          'X-Request-ID',
        ],
        capturedResponseHeaders: const [
          'Content-Type',
          'X-Request-ID',
          'Server',
        ],
      ),
      HttpUrlModuleConfiguration(
        isEnabled: true,
        capturedRequestHeaders: const [
          'Accept',
          'Content-Type',
          'X-Request-ID',
        ],
        capturedResponseHeaders: const [
          'Content-Type',
          'X-Request-ID',
          'Server',
        ],
      ),
      OkHttp3AutoModuleConfiguration(
        isEnabled: true,
        capturedRequestHeaders: const [
          'Accept',
          'Content-Type',
          'X-Request-ID',
        ],
        capturedResponseHeaders: const [
          'Content-Type',
          'X-Request-ID',
          'Server',
        ],
      ),
    ],
  );

  stopwatch.stop();
  debugPrint('=============');
  debugPrint('SplunkRum.install() took: ${stopwatch.elapsedMilliseconds} ms');
  debugPrint('=============');

  final sessionReplay = SplunkSessionReplay.instance;
  await sessionReplay.start();
  debugPrint('Session replay started');

  final coreStateStatus = await SplunkRum.instance.state.getStatus();
  debugPrint('Core status: $coreStateStatus');

  final status = await sessionReplay.getStatus();
  debugPrint('Session replay status: $status');

  Future<void>.delayed(const Duration(seconds: 1)).then((_) async {
    final sessionId = await SplunkRum.instance.session.state.getId();

    debugPrint('-------------');
    debugPrint('Session id: $sessionId');

    // Persist the session id to the app's temporary directory so it can be
    // retrieved from a real (wireless) device without attaching a VM Service /
    // debugger. Directory.systemTemp maps to <container>/tmp on iOS. Pull it
    // off the device with:
    //   xcrun devicectl device copy from --device <udid> \
    //     --domain-type appDataContainer \
    //     --domain-identifier com.splunk.rum.flutter.root.exampleapp.rootExampleApp \
    //     --source tmp/session_id.txt --destination /tmp/session_id.txt
    try {
      final file = File('${Directory.systemTemp.path}/session_id.txt');
      await file.writeAsString('Session id: $sessionId\n');
      debugPrint('Wrote session id to ${file.path}');
    } catch (error) {
      debugPrint('Failed to persist session id: $error');
    }
  });

  Future<void>.delayed(const Duration(seconds: 1)).then((_) async {
    // Set endpoint configuration after install.
    await SplunkRum.instance.preferences.setEndpointConfiguration(
      endpoint: EndpointConfiguration.forRum(
        realm: realm,
        rumAccessToken: rumAccessToken,
      ),
    );
    debugPrint('Endpoint configuration set after install.');
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
