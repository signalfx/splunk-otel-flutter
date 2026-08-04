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

    BackgroundLaunchProbe.shared.logDidFinishLaunching(application: application, launchOptions: launchOptions)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    BackgroundLaunchProbe.shared.logDidBecomeActive()
    super.applicationDidBecomeActive(application)
  }

  // Silent-push handler. When the app is not running, a content-available push
  // launches the process into the background: `didFinishLaunching` fires and this
  // callback runs, but `didBecomeActive` does NOT happen until the user foregrounds
  // the app later. The native SplunkAgent still anchors a cold start at BSD
  // process-start, so the whole background-residence window is reported as
  // cold-start latency.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    BackgroundLaunchProbe.shared.logDidReceiveRemoteNotification(application: application)

    // Keep the process alive briefly so the background residence is observable,
    // then report completion so iOS does not terminate us prematurely.
    completionHandler(.noData)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    BackgroundLaunchProbe.shared.log("Registered for remote notifications (token bytes: \(deviceToken.count))")
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    // Expected on the Simulator without a real APNs environment; silent pushes are
    // still delivered locally via `xcrun simctl push`.
    BackgroundLaunchProbe.shared.log("Failed to register for remote notifications: \(error.localizedDescription)")
  }
}

/// Debug-only helper that logs lifecycle timing for the background-launch cold-start
/// simulation. It reads the real BSD process-start time (the same anchor the native
/// SplunkAgent uses for cold starts) so we can predict the duration the SDK will report.
final class BackgroundLaunchProbe {

  static let shared = BackgroundLaunchProbe()

  private let prefix = "[BG-LAUNCH-PROBE]"

  private init() {}

  func logDidFinishLaunching(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
    let state = Self.description(for: application.applicationState)
    let launchedFromPush = launchOptions?[.remoteNotification] != nil
    log("didFinishLaunching — applicationState=\(state), launchedFromRemoteNotification=\(launchedFromPush)")
    if let processStart = Self.processStartDate() {
      log("Process start (BSD, cold-start anchor): \(Self.format(processStart))")
      log("Elapsed since process start: \(String(format: "%.3f", Date().timeIntervalSince(processStart)))s")
    }
  }

  func logDidReceiveRemoteNotification(application: UIApplication) {
    let state = Self.description(for: application.applicationState)
    log("didReceiveRemoteNotification (silent push) — applicationState=\(state)")
  }

  func logDidBecomeActive() {
    let now = Date()
    log("didBecomeActive at \(Self.format(now))")
    guard let processStart = Self.processStartDate() else {
      return
    }

    let delta = now.timeIntervalSince(processStart)

    log("process-start -> didBecomeActive delta: \(String(format: "%.3f", delta))s")
    log("=> If classified COLD, the SDK will report an AppStart span of ~\(String(format: "%.3f", delta))s")
  }

  func log(_ message: String) {
    // Intentionally unconditional: this is a demo/example app and the probe output
    // is the primary way to observe the background-launch cold-start simulation.
    NSLog("%@ %@", prefix, message)
  }

  // MARK: - Process start (BSD)

  /// Returns the real process-start time via `sysctl(KERN_PROC_PID)`, mirroring the
  /// native SDK's cold-start anchor.
  private static func processStartDate() -> Date? {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

    let result = mib.withUnsafeMutableBufferPointer { pointer -> Int32 in
      sysctl(pointer.baseAddress, u_int(pointer.count), &info, &size, nil, 0)
    }

    guard result == 0 else {
      return nil
    }

    let startTime = info.kp_proc.p_starttime
    let seconds = TimeInterval(startTime.tv_sec)
    let microseconds = TimeInterval(startTime.tv_usec) / 1_000_000

    return Date(timeIntervalSince1970: seconds + microseconds)
  }

  private static func description(for state: UIApplication.State) -> String {
    switch state {
    case .active:
      return "active"
    case .inactive:
      return "inactive"
    case .background:
      return "background"
    @unknown default:
      return "unknown"
    }
  }

  private static func format(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    return formatter.string(from: date)
  }
}
