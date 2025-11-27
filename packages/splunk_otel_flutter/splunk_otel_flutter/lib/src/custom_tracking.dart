import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class CustomTracking {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<void> trackCustomEvent({
    required String name,
    required MutableAttributes attributes,
  }) async =>
      await _delegate.customTrackingTrackCustomEvent(
        name: name,
        attributes: attributes,
      );

  Future<void> trackWorkflow({
    required String workflowName,
  }) async =>
      await _delegate.customTrackingTrackWorkflow(
        workflowName: workflowName,
      );
}
