import 'package:splunk_otel_flutter_platform_interface/model/agent_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/model/module_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/platform_interface/splunk_otel_flutter_platform_interface.dart';

class SplunkOtelFlutterPlatformImplementation
    extends SplunkOtelFlutterPlatformInterface {
  SplunkOtelFlutterPlatformImplementation._();

  static SplunkOtelFlutterPlatformImplementation get instance {
    return SplunkOtelFlutterPlatformImplementation._();
  }

  @override
  Future<void> install({required AgentConfiguration agentConfiguration, required List<ModuleConfiguration> moduleConfigurations}) async {
    //TODO native install
  }
}
