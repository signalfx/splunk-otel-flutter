/*
Copyright 2025 Splunk Inc.

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

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.splunk.rum.flutter.example", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "simulateSlowRender":
        self.simulateSlowRender(result: result)
      case "simulateFrozenRender":
        self.simulateFrozenRender(result: result)
      case "testURLSessionGet":
        self.performURLSessionRequest(result: result)

      case "simulateCrash":
        self.forceCrash()

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private func simulateSlowRender(result: @escaping FlutterResult) {
      //TODO
    }
    
    private func simulateFrozenRender(result: @escaping FlutterResult) {
      //TODO
    }


  private func performURLSessionRequest(result: @escaping FlutterResult) {
    guard let url = URL(string: "https://httpbin.org/get") else {
      result(FlutterError(code: "bad_url", message: "Invalid URL", details: nil))
      return
    }

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
      if let error = error {
        result(FlutterError(code: "network_error", message: error.localizedDescription, details: nil))
        return
      }

      let status = (response as? HTTPURLResponse)?.statusCode ?? -1
      result("iOS URLSession GET completed (status: \(status))")
    }

    task.resume()
  }

  private func forceCrash() {
    // This intentionally crashes the app to test crash reporting.
    fatalError("Test crash triggered from Flutter method channel")
  }
}

