import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:splunk_otel_flutter_platform_interface/implementation/splunk_otel_flutter_platform_implementation.dart';

abstract class SplunkOtelFlutterPlatformInterface extends PlatformInterface {

  SplunkOtelFlutterPlatformInterface(): super(token: _token);

  static final Object _token = Object();

  static SplunkOtelFlutterPlatformInterface? _instance;

  static SplunkOtelFlutterPlatformInterface get instance {
    return _instance ??= SplunkOtelFlutterPlatformImplementation.instance;
  }

  static set instance(SplunkOtelFlutterPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }
}
