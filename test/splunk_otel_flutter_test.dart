import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter_platform_interface.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSplunkOtelFlutterPlatform
    with MockPlatformInterfaceMixin
    implements SplunkOtelFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SplunkOtelFlutterPlatform initialPlatform = SplunkOtelFlutterPlatform.instance;

  test('$MethodChannelSplunkOtelFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSplunkOtelFlutter>());
  });

  test('getPlatformVersion', () async {
    SplunkOtelFlutter splunkOtelFlutterPlugin = SplunkOtelFlutter();
    MockSplunkOtelFlutterPlatform fakePlatform = MockSplunkOtelFlutterPlatform();
    SplunkOtelFlutterPlatform.instance = fakePlatform;

    expect(await splunkOtelFlutterPlugin.getPlatformVersion(), '42');
  });
}
