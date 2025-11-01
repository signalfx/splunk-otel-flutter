import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class State {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<String> getAppName() async => await _delegate.stateGetAppName();

  Future<String> getAppVersion() async => await _delegate.stateGetAppVersion();

  Future<Status> getStatus() async => await _delegate.stateGetStatus();

  Future<EndpointConfiguration> getEndpointConfiguration() async => await _delegate.stateGetEndpointConfiguration();

  Future<String> getDeploymentEnvironment() async => await _delegate.stateGetDeploymentEnvironment();

  Future<bool> getIsDebugLoggingEnabled() async => await _delegate.stateGetIsDebugLoggingEnabled();

  Future<String?> getInstrumentedProcessName() async => await _delegate.stateGetInstrumentedProcessName();

  Future<bool> getDeferredUntilForeground() async => await _delegate.stateGetDeferredUntilForeground();
}

