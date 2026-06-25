import 'package:flutter/widgets.dart';

const bool enableSauceTestMode = bool.fromEnvironment('ENABLE_SAUCE_TEST_MODE');
const bool enableAppiumSemantics = bool.fromEnvironment(
  'ENABLE_APPIUM_SEMANTICS',
);
const bool enableNativeCrashTestHelpers =
    bool.fromEnvironment('ENABLE_NATIVE_CRASH_TEST_HELPERS') ||
    enableSauceTestMode;
const bool enableInstallTimeEndpointConfiguration =
    bool.fromEnvironment('ENABLE_INSTALL_TIME_ENDPOINT_CONFIGURATION') ||
    enableSauceTestMode;
const bool enableRumDebugLogging =
    bool.fromEnvironment('ENABLE_RUM_DEBUG_LOGGING') || enableSauceTestMode;
const bool enableCrashLifecycleModules =
    bool.fromEnvironment('ENABLE_CRASH_LIFECYCLE_MODULES') ||
    enableSauceTestMode;

Widget appiumSemantics({
  required Widget child,
  String? label,
  bool button = false,
  bool textField = false,
}) {
  if (!enableAppiumSemantics) {
    return child;
  }

  return Semantics(
    label: label,
    button: button,
    textField: textField,
    child: child,
  );
}
