
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:splunk_otel_flutter_platform_interface/implementation/splunk_otel_flutter_platform_implementation.dart';
import 'package:splunk_otel_flutter_platform_interface/model/agent_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/model/module_configuration.dart';

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

  Future<void> install({required AgentConfiguration agentConfiguration, required List<ModuleConfiguration> moduleConfigurations});
}
