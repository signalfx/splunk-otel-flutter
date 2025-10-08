import 'package:pigeon/pigeon.dart';


@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/pigeon/messages.pigeon.dart',
    dartTestOut: 'test/pigeon/test_api.dart',
    dartPackageName: 'splunk_otel_flutter_session_replay_platform_interface',
    kotlinOut:
    '../splunk_otel_flutter_session_replay/android/src/main/kotlin/com/splunk/rum/flutter/GeneratedAndroidSplunkOtelFlutterSessionReplay.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.splunk.rum.flutter.sessionreplay',
    ),
    swiftOut:
    '../splunk_otel_flutter_session_replay/ios/splunk_otel_flutter_session_replay/Sources/splunk_otel_flutter_session_replay/SplunkOtelFlutterSessionReplayMessages.g.swift',
  ),
)

@HostApi(dartHostTestHandler: 'TestSplunkOtelFlutterSessionReplayHostApi')
abstract class SplunkOtelFlutterSessionReplayHostApi {
  @async
  void install();
}
