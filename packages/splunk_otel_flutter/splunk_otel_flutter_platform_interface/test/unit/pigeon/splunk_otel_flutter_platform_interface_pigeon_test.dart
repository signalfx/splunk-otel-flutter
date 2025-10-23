import 'package:flutter_test/flutter_test.dart';
import '../../mock_splunk_otel_flutter_platform_interface_host_api.dart';
import '../../pigeon/test_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pigeon API Smoke Tests', () {
    test('mock API setup should work', () {
      final mockApi = MockSplunkOtelFlutterPlatformInterfaceHostApi();
      TestSplunkOtelFlutterHostApi.setUp(mockApi);

      expect(mockApi, isNotNull);

      TestSplunkOtelFlutterHostApi.setUp(null);
    });
  });
}
