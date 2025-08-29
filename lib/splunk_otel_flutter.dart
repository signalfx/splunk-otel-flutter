
import 'splunk_otel_flutter_platform_interface.dart';

class SplunkOtelFlutter {
  Future<String?> getPlatformVersion() {
    return SplunkOtelFlutterPlatform.instance.getPlatformVersion();
  }
}
