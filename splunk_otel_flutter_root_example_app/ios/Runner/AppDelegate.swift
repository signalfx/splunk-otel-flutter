/*
Copyright 2026 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register for remote notifications so the OS can wake/launch the process in
    // the background for silent (content-available) pushes. This is what lets us
    // reproduce the "background launch inflates cold start" scenario on iOS.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Silent-push handler. When the app is not running, a content-available push
  // launches the process into the background: didFinishLaunching fires and this
  // callback runs, but didBecomeActive does NOT happen until the user foregrounds
  // the app later. The native SplunkAgent still anchors a cold start at BSD
  // process-start, so the whole background-residence window is reported as
  // cold-start latency. See tool/simulate_background_launch.sh.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    completionHandler(.noData)
  }
}
