import 'package:splunk_otel_flutter_platform_interface/model/module_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/implementation/splunk_otel_flutter_platform_implementation.dart';
import 'package:splunk_otel_flutter_platform_interface/model/agent_configuration.dart';

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
    _delegate.install(
        agentConfiguration: agentConfiguration,
        moduleConfigurations: moduleConfigurations);
  }
}

// not sure if to put here or interface package yet
class SlowRenderingModuleConfiguration extends ModuleConfiguration {
  final Duration interval;

  SlowRenderingModuleConfiguration({
    super.isEnabled = true,
    this.interval = const Duration(seconds: 1),
  });
}

class NavigationModuleConfiguration extends ModuleConfiguration {
  final bool isAutomatedTrackingEnabled;

  NavigationModuleConfiguration({
    super.isEnabled = true,
    this.isAutomatedTrackingEnabled = false,
  });
}
