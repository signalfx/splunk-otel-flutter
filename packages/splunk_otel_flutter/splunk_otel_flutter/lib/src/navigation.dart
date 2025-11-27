import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class Navigation {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<void> track({
    required String screenName,
  }) async =>
      await _delegate.navigationTrack(
        screenName: screenName,
      );
}

