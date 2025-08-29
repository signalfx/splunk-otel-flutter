import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'splunk_otel_flutter_method_channel.dart';

abstract class SplunkOtelFlutterPlatform extends PlatformInterface {
  /// Constructs a SplunkOtelFlutterPlatform.
  SplunkOtelFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static SplunkOtelFlutterPlatform _instance = MethodChannelSplunkOtelFlutter();

  /// The default instance of [SplunkOtelFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelSplunkOtelFlutter].
  static SplunkOtelFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SplunkOtelFlutterPlatform] when
  /// they register themselves.
  static set instance(SplunkOtelFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
