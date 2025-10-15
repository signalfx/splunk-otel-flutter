abstract class ModuleConfiguration {
  final bool isEnabled;
  ModuleConfiguration({required this.isEnabled});
}

class SlowRenderingModuleConfiguration extends ModuleConfiguration {
  final Duration interval;

  SlowRenderingModuleConfiguration({
    super.isEnabled = true,
    this.interval = const Duration(seconds: 1),
  });
}

class NavigationModuleConfiguration extends ModuleConfiguration {
  final bool isAutomatedTrackingEnabled;

  NavigationModuleConfiguration({
    super.isEnabled = true,
    this.isAutomatedTrackingEnabled = false,
  });
}

/* TODO to be decided
class AppStartModuleConfiguration extends ModuleConfiguration{

}

class CrashReportsModuleConfiguration extends ModuleConfiguration{

}

class CustomTrackingModuleConfiguration extends ModuleConfiguration{

}

class InteractionsModuleConfiguration extends ModuleConfiguration{

}

class NetworkMonitorModuleConfiguration extends ModuleConfiguration{

}

class SessionReplayModuleConfiguration extends ModuleConfiguration{

}

class WebViewModuleConfiguration extends ModuleConfiguration{

}

// only Android

class AnrModuleConfiguration extends ModuleConfiguration{

}

class ApplicationLifecycleModuleConfiguration extends ModuleConfiguration{

}

class HttpUrlModuleConfiguration extends ModuleConfiguration{

}

class OkHttp3AutoModuleConfiguration extends ModuleConfiguration{

}

class OkHttp3ManualModuleConfiguration extends ModuleConfiguration{

}*/

