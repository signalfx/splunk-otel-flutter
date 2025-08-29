import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'splunk_otel_flutter_platform_interface.dart';

/// An implementation of [SplunkOtelFlutterPlatform] that uses method channels.
class MethodChannelSplunkOtelFlutter extends SplunkOtelFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('splunk_otel_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
