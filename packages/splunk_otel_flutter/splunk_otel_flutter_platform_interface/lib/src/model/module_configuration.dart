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

