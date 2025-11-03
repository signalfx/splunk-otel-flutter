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
      endpoint: EndpointConfiguration.forRum(
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
      NavigationModuleConfiguration(isEnabled: true),
      SlowRenderingModuleConfiguration(isEnabled: false),
    ],
  );

  await SplunkOtelFlutter.instance.sessionReplay.start();

  final sessionId = await SplunkOtelFlutter.instance.session.state.getId();

  SplunkOtelFlutter.instance.globalAttributes.setBool(key: "boolKey2", value: true);

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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: const Center(child: Text('Running on:')),
      ),
    );
  }
}
