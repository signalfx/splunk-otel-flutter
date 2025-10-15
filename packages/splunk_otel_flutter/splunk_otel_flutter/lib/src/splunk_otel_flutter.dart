import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class SplunkOtelFlutter {
  static final SplunkOtelFlutter _instance = SplunkOtelFlutter._internal();

  SplunkOtelFlutter._internal();

  static SplunkOtelFlutter get instance {
    return _instance;
  }

  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  // TODO Android needs App so we will need to attach app from flutter engine
  Future<void> install({
    required AgentConfiguration agentConfiguration,
    required List<ModuleConfiguration> moduleConfigurations,
  }) async {
    await _delegate.install(
        agentConfiguration: agentConfiguration,
        moduleConfigurations: moduleConfigurations);
  }

  Future<void> startSessionReplay() async {
    await _delegate.sessionReplayStart();
  }

  Future<String> getSessionId() async{
    return await _delegate.getSessionId();
  }
}
