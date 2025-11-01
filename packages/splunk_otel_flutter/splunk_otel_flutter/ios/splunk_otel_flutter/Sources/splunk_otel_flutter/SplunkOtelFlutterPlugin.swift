//
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
        
        //let mutableAttribues = mutableAttributes(from: agentConfiguration.globalAttributes)
        
        let agentConfig = AgentConfiguration(
            endpoint: endpointConfig,
            appName: agentConfiguration.appName,
            deploymentEnvironment: agentConfiguration.deploymentEnvironment,
        )
            .appVersion(agentConfiguration.appVersion ?? "")
            .enableDebugLogging(agentConfiguration.enableDebugLogging ?? false)
            //.globalAttributes(mutableAttribues)
            .sessionConfiguration(SessionConfiguration(samplingRate: agentConfiguration.session?.samplingRate ?? 1.0))
            .userConfiguration(UserConfiguration(trackingMode: agentConfiguration.user?.trackingMode == .anonymousTracking ? .anonymousTracking : .noTracking))
        do {
           let agent = try SplunkRum.install(with: agentConfig,
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

