import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class SessionReplay {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;
  final preferences = SessionReplayPreferences();
  final state = SessionReplayState();
  final recordingMask = SessionReplayRecordingMaskApi();

  Future<void> start() async => await _delegate.sessionReplayStart();

  Future<void> stop() async => await _delegate.sessionReplayStop();
}

class SessionReplayPreferences {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<RenderingMode?> getRenderingMode() async =>
      await _delegate.sessionReplayPreferencesGetRenderingMode();

  Future<void> setRenderingMode({
    required RenderingMode? renderingMode,
  }) async =>
      await _delegate.sessionReplayPreferencesSetRenderingMode(
        renderingMode: renderingMode,
      );
}

class SessionReplayState {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<RenderingMode> getRenderingMode() async =>
      await _delegate.sessionReplayStateGetRenderingMode();

  Future<SessionReplayStatus> getStatus() async =>
      await _delegate.sessionReplayStateGetStatus();
}

class SessionReplayRecordingMaskApi {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<RecordingMaskList?> getRecordingMask() async =>
      await _delegate.sessionReplayGetRecordingMask();

  Future<void> setRecordingMask({
    required RecordingMaskList recordingMask,
  }) async =>
      await _delegate.sessionReplaySetRecordingMask(
        recordingMask: recordingMask,
      );
}
