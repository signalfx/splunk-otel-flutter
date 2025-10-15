import Flutter
import UIKit
import SplunkAgent
import OpenTelemetryApi
import SplunkSlowFrameDetector
import SplunkNavigation

extension FlutterError: Error {}

public class SplunkOtelFlutterPlugin: NSObject, FlutterPlugin, SplunkOtelFlutterHostApi {
  
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SplunkOtelFlutterPlugin()

        SplunkOtelFlutterHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    }
    
    func install(agentConfiguration: GeneratedAgentConfiguration,
                 navigationModuleConfiguration: GeneratedNavigationModuleConfiguration,
                 slowRenderingModuleConfiguration: GeneratedSlowRenderingModuleConfiguration,
                 completion: @escaping (Result<Void, any Error>) -> Void) {
        
        let endpointConfig = EndpointConfiguration(
            realm: agentConfiguration.endpoint.realm,
            rumAccessToken: agentConfiguration.endpoint.rumAccessToken,
        )
        
        let agentConfig = AgentConfiguration(
            endpoint: endpointConfig,
            appName: agentConfiguration.appName,
            deploymentEnvironment: agentConfiguration.deploymentEnvironment,
        )
            .appVersion(agentConfiguration.appVersion ?? "")
            .enableDebugLogging(agentConfiguration.enableDebugLogging)
        do {
            _ = try SplunkRum.install(with: agentConfig,
                                              moduleConfigurations: [
                                                SlowFrameDetectorConfiguration(isEnabled: slowRenderingModuleConfiguration.isEnabled),
                                                NavigationConfiguration(isEnabled: navigationModuleConfiguration.isEnabled,enableAutomatedTracking: navigationModuleConfiguration.isAutomatedTrackingEnabled)
                                                // TODO rest configurations
                                              ]
            )
            
            completion(.success(()))
        } catch {
            completion(
                .failure(
                    FlutterError(
                        code: "INSTALL_FAILED",
                        message: error.localizedDescription,
                        details: nil,
                    )
                )
            )
        }
         
        
        completion(.success(()))
    }
    
    
    func sessionReplayStart(completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.sessionReplay.start()
        
        completion(.success(()))
    }
    
    func getSessionId(completion: @escaping (Result<String, any Error>) -> Void) {
        completion(.success(SplunkRum.shared.session.state.id))
    }
    
    
}

