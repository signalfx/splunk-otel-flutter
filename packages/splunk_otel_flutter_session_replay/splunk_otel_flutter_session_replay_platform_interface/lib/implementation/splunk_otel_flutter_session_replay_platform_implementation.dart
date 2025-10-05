

import 'package:splunk_otel_flutter_session_replay_platform_interface/platform_interface/splunk_otel_flutter_session_replay_platform_interface.dart';

class SplunkOtelFlutterSessionReplayPlatformImplementation extends SplunkOtelFlutterSessionReplayPlatformInterface{

  SplunkOtelFlutterSessionReplayPlatformImplementation._();

  static SplunkOtelFlutterSessionReplayPlatformImplementation get instance {
    return SplunkOtelFlutterSessionReplayPlatformImplementation._();
  }
}