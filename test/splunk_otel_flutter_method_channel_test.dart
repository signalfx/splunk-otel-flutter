import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelSplunkOtelFlutter platform = MethodChannelSplunkOtelFlutter();
  const MethodChannel channel = MethodChannel('splunk_otel_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
