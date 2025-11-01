import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class Session {
  final state = SessionState();
}

class SessionState {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<String> getId() async => await _delegate.sessionStateGetId();

  Future<double> getSamplingRate() async => await _delegate.sessionStateGetSamplingRate();
}
