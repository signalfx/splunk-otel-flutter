// Mock implementation


import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';
import 'pigeon/test_api.dart';

class MockSplunkOtelFlutterPlatformInterfaceHostApi implements TestSplunkOtelFlutterHostApi {
  Future<void> Function(
      GeneratedAgentConfiguration agentConfiguration,
      GeneratedNavigationModuleConfiguration navigationModuleConfiguration,
      GeneratedSlowRenderingModuleConfiguration slowRenderingModuleConfiguration,
      )? installHandler;

  Future<void> Function()? sessionReplayStartHandler;
  Future<String> Function()? getSessionIdHandler;

  @override
  Future<void> install({
    required GeneratedAgentConfiguration agentConfiguration,
    required GeneratedNavigationModuleConfiguration navigationModuleConfiguration,
    required GeneratedSlowRenderingModuleConfiguration slowRenderingModuleConfiguration,
  }) async {
    if (installHandler != null) {
      return installHandler!(
        agentConfiguration,
        navigationModuleConfiguration,
        slowRenderingModuleConfiguration,
      );
    }
  }

  @override
  Future<void> sessionReplayStart() async {
    if (sessionReplayStartHandler != null) {
      return sessionReplayStartHandler!();
    }
  }

  @override
  Future<String> getSessionId() async {
    if (getSessionIdHandler != null) {
      return getSessionIdHandler!();
    }
    return 'default-session-id';
  }
}