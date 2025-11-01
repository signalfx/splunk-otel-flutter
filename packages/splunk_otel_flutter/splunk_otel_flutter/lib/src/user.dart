import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';

class User {
  final state = UserState();
  final preferences = UserPreferences();
}

class UserState {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<UserTrackingMode> getTrackingMode() async =>
      await _delegate.userStateGetUserTrackingMode();
}

class UserPreferences {
  final _delegate = SplunkOtelFlutterPlatformImplementation.instance;

  Future<UserTrackingMode?> getTrackingMode() async =>
      await _delegate.userPreferencesGetUserTrackingMode();

  Future<void> setTrackingMode({
    required UserTrackingMode? userTrackingMode,
  }) async =>
      await _delegate.userPreferencesSetUserTrackingMode(
        userTrackingMode: userTrackingMode,
      );
}
