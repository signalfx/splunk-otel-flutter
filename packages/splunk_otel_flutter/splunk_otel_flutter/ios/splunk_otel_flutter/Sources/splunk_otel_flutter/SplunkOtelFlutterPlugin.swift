import Flutter
import UIKit
import SplunkAgent
import OpenTelemetryApi
import SplunkSlowFrameDetector

public class SplunkOtelFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
 let channel = FlutterMethodChannel(name: "splunkotelflutter", binaryMessenger: registrar.messenger())
    let instance = SplunkOtelFlutterPlugin()

      let endpointConfig = EndpointConfiguration(
          realm: "",
          rumAccessToken: ""
      )

      let agentConfig = AgentConfiguration(
          endpoint: endpointConfig,
          appName: "Flutter agent app",
          deploymentEnvironment: "test-ios"
      )
          .enableDebugLogging(true)
          .globalAttributes(MutableAttributes(dictionary: [
              "teststring": .string("value"),
              "testint": .int(100)]))
          .spanInterceptor { spanData in
              var attributes = spanData.attributes
              attributes["test_attribute"] = AttributeValue("test_value")

              var modifiedSpan = spanData
              modifiedSpan.settingAttributes(attributes)

              return modifiedSpan
          }
      do {
          _ = try SplunkRum.install(with: agentConfig,
                                    moduleConfigurations: [SlowFrameDetectorConfiguration(isEnabled: true)])
      } catch {
          print("Unable to start the Splunk agent, error: \(error)")
      }

      // Navigation Instrumentation
      SplunkRum.shared.navigation.preferences.enableAutomatedTracking = true
      SplunkRum.shared.slowFrameDetector

      // Start session replay
      SplunkRum.shared.sessionReplay.start()

      // API to update Global Attributes
      SplunkRum.shared.globalAttributes.setBool(true, for: "isWorkingHard")
      SplunkRum.shared.globalAttributes[string: "secret"] = "Monster"

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
