/*
 * Copyright 2025 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

