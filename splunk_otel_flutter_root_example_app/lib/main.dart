import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/native_crash.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/welcome_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/test_flags.dart';
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

SemanticsHandle? _appiumSemanticsHandle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (enableAppiumSemantics) {
    _appiumSemanticsHandle = SemanticsBinding.instance.ensureSemantics();
    debugPrint('Appium semantics enabled: ${_appiumSemanticsHandle != null}');
  }

  ///* Set through --dart-define for flutter run
  /// --dart-define=REALM=your_realm
  /// --dart-define=RUM_ACCESS_TOKEN=your_token
  const String realm = String.fromEnvironment('REALM');
  const String rumAccessToken = String.fromEnvironment('RUM_ACCESS_TOKEN');
  const int crashUploadGraceSeconds = int.fromEnvironment(
    'CRASH_UPLOAD_GRACE_SECONDS',
  );
  final endpoint =
      enableInstallTimeEndpointConfiguration &&
          realm.isNotEmpty &&
          rumAccessToken.isNotEmpty
      ? EndpointConfiguration.forRum(
          realm: realm,
          rumAccessToken: rumAccessToken,
        )
      : null;

  if (enableInstallTimeEndpointConfiguration && endpoint == null) {
    debugPrint(
      'Installing SplunkRum without endpoint: REALM or RUM_ACCESS_TOKEN is empty',
    );
  }

  if (enableNativeCrashTestHelpers && crashUploadGraceSeconds > 0) {
    await installCrashUploadGrace(
      const Duration(seconds: crashUploadGraceSeconds),
    );
    debugPrint('Crash upload grace enabled: ${crashUploadGraceSeconds}s');
  }

  final stopwatch = Stopwatch()..start();
  final agentConfiguration = endpoint != null || enableRumDebugLogging
      ? AgentConfiguration(
          endpoint: endpoint,
          appName: "Flutter Splunk cinema demo",
          deploymentEnvironment: 'test',
          enableDebugLogging: enableRumDebugLogging,
        )
      : AgentConfiguration(
          appName: "Flutter Splunk cinema demo",
          deploymentEnvironment: 'test',
        );

  await SplunkRum.instance.install(
    agentConfiguration: agentConfiguration,
    moduleConfigurations: [
      if (enableCrashLifecycleModules) ...[
        CrashReportsModuleConfiguration(isEnabled: true),
        ApplicationLifecycleModuleConfiguration(isEnabled: true),
      ],
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
  });

  if (!enableInstallTimeEndpointConfiguration) {
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
  }

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
