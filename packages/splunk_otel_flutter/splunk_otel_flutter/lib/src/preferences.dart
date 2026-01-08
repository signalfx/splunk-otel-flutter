import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class Preferences {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<EndpointConfiguration?> getEndpointConfiguration() async =>
      await _delegate.preferencesGetEndpointConfiguration();
}

