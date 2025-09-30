import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:splunk_otel_flutter_session_replay_platform_interface/implementation/splunk_otel_flutter_session_replay_platform_implementation.dart';


abstract class SplunkOtelFlutterSessionReplayPlatformInterface extends PlatformInterface {

  SplunkOtelFlutterSessionReplayPlatformInterface(): super(token: _token);

  static final Object _token = Object();

  static SplunkOtelFlutterSessionReplayPlatformInterface? _instance;

  static SplunkOtelFlutterSessionReplayPlatformInterface get instance {
    return _instance ??= SplunkOtelFlutterSessionReplayPlatformImplementation.instance;
  }

  static set instance(SplunkOtelFlutterSessionReplayPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }
}
