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
        
        
        

        
        guard let endpointConfiguration = agentConfiguration.endpoint.toEndpointConfiguration() else {
            completion(
                .failure(
                    FlutterError(
                        code: "INSTALL_FAILED",
                        message: "Endpoint configuration - Invalid parameter combination",
                        details: nil
                    )
                )
            )
            return
        }
        
        let mutableAttributes = agentConfiguration.globalAttributes?.toMutableAttributes()
        
        let agentConfig = AgentConfiguration(
            endpoint: endpointConfiguration,
            appName: agentConfiguration.appName,
            deploymentEnvironment: agentConfiguration.deploymentEnvironment,
        )
            .appVersion(agentConfiguration.appVersion ?? "")
            .enableDebugLogging(agentConfiguration.enableDebugLogging ?? false)
            .globalAttributes(mutableAttributes ?? MutableAttributes())
            .sessionConfiguration(SessionConfiguration(samplingRate: agentConfiguration.session?.samplingRate ?? 1.0))
            .userConfiguration(UserConfiguration(trackingMode: agentConfiguration.user?.trackingMode == .anonymousTracking ? .anonymousTracking : .noTracking))
        do {
           try SplunkRum.install(with: agentConfig,
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
    
    // Session replay
    
    // MARK: - Session Replay
    
    func sessionReplayStart(completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.sessionReplay.start()
        
        completion(.success(()))
    }
    
    func sessionReplayStop(completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.sessionReplay.stop()
        
        completion(.success(()))
    }
    
    func sessionReplayStateGetStatus(completion: @escaping (Result<GeneratedSessionReplayStatus, any Error>) -> Void) {
        let status = SplunkRum.shared.sessionReplay.state.status
        
        completion(.success(status.toGeneratedSessionReplayStatus()))
    }
    
    func sessionReplayStateGetRenderingMode(completion: @escaping (Result<GeneratedRenderingMode, any Error>) -> Void) {
        let renderingMode = SplunkRum.shared.sessionReplay.state.renderingMode
        
        completion(.success(renderingMode.toGeneratedRenderingMode()))
    }
    
    func sessionReplayPreferencesGetRenderingMode(completion: @escaping (Result<GeneratedRenderingMode?, any Error>) -> Void) {
        let renderingMode = SplunkRum.shared.sessionReplay.preferences.renderingMode
        
        completion(.success(renderingMode?.toGeneratedRenderingMode()))
    }
    
    func sessionReplayPreferencesSetRenderingMode(renderingMode: GeneratedRenderingMode?, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.sessionReplay.preferences.renderingMode = renderingMode?.toRenderingMode()
        
        completion(.success(()))
    }
    
    func sessionReplayGetRecordingMask(completion: @escaping (Result<GeneratedRecordingMaskList?, any Error>) -> Void) {
        let recordingMask = SplunkRum.shared.sessionReplay.recordingMask
        
        completion(.success(recordingMask?.toGeneratedRecordingMaskList()))
    }
    
    func sessionReplaySetRecordingMask(recordingMask: GeneratedRecordingMaskList?, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.sessionReplay.recordingMask = recordingMask?.toRecordingMask()
        
        completion(.success(()))
    }
    
    // MARK: - State
    
    func stateGetAppName(completion: @escaping (Result<String, any Error>) -> Void) {
        let appName = SplunkRum.shared.state.appName
        
        completion(.success(appName))
    }
    
    func stateGetAppVersion(completion: @escaping (Result<String, any Error>) -> Void) {
        let appVersion = SplunkRum.shared.state.appVersion
        
        completion(.success(appVersion))
    }
    
    func stateGetStatus(completion: @escaping (Result<GeneratedStatus, any Error>) -> Void) {
        let status = SplunkRum.shared.state.status
        
        completion(.success(status.toGeneratedStatus()))
    }
    
    func stateGetEndpointConfiguration(completion: @escaping (Result<GeneratedEndpointConfiguration, any Error>) -> Void) {
        let endpointConfiguration = SplunkRum.shared.state.endpointConfiguration
        
        completion(.success(endpointConfiguration.toGeneratedEndpointConfiguration()))
    }
    
    func stateGetDeploymentEnvironment(completion: @escaping (Result<String, any Error>) -> Void) {
        let environment = SplunkRum.shared.state.deploymentEnvironment
        
        completion(.success(environment))
    }
    
    func stateGetIsDebugLoggingEnabled(completion: @escaping (Result<Bool, any Error>) -> Void) {
        let isDebugLoggingEnabled = SplunkRum.shared.state.isDebugLoggingEnabled
        
        completion(.success(isDebugLoggingEnabled))
    }
    
    func stateGetInstrumentedProcessName(completion: @escaping (Result<String?, any Error>) -> Void) {
        completion(.success(nil))
    }
    
    func stateGetDeferredUntilForeground(completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(false))
    }
    
    // MARK: - Session
    
    func sessionStateGetId(completion: @escaping (Result<String, any Error>) -> Void) {
        let sessionId = SplunkRum.shared.session.state.id
        
        completion(.success(sessionId))
    }
    
    func sessionStateGetSamplingRate(completion: @escaping (Result<Double, any Error>) -> Void) {
        let samplingRate = SplunkRum.shared.session.state.samplingRate
        
        completion(.success(samplingRate))
    }
    
    // MARK: - User
    
    func userStateGetUserTrackingMode(completion: @escaping (Result<GeneratedUserTrackingMode, any Error>) -> Void) {
        let trackingMode = SplunkRum.shared.user.state.trackingMode
        
        completion(.success(trackingMode.toGeneratedUserTrackingMode()))
    }
    
    func userPreferencesGetUserTrackingMode(completion: @escaping (Result<GeneratedUserTrackingMode?, any Error>) -> Void) {
        let trackingMode = SplunkRum.shared.user.preferences.trackingMode
        
        completion(.success(trackingMode.toGeneratedUserTrackingMode()))
    }
    
    func userPreferencesSetUserTrackingMode(trackingMode: GeneratedUserTrackingMode, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.user.preferences.trackingMode = trackingMode.toUserTrackingMode()
        
        completion(.success(()))
    }
    
    // MARK: - Global Attributes
    
    func globalAttributesGet(key: String, completion: @escaping (Result<Any?, any Error>) -> Void) {
        let attribute = SplunkRum.shared.globalAttributes.getValue(for: key)
        let convertedAttribute = attribute?.toGeneratedWrapper()
        
        completion(.success(convertedAttribute))
    }
    
    func globalAttributesGetAll(completion: @escaping (Result<GeneratedMutableAttributes?, Error>) -> Void) {
        let attributes = SplunkRum.shared.globalAttributes.getAll()

        var converted: [String: Any?] = [:]
        for (key, value) in attributes {
            converted[key] = value.toGeneratedWrapper()
        }
        let generated = GeneratedMutableAttributes(attributes: converted)
        
        completion(.success(generated))
    }
    
    func globalAttributesRemove(key: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.remove(for: key)
        
        completion(.success(()))
    }
    
    func globalAttributesRemoveAll(completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.removeAll()
        
        completion(.success(()))
    }
    
    func globalAttributesContains(key: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        let doesContain = SplunkRum.shared.globalAttributes.contains(key: key)
        
        completion(.success(doesContain))
    }
    
    func globalAttributesSetString(key: String, value: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.setString(value, for: key)
        
        completion(.success(()))
    }
    
    func globalAttributesSetInt(key: String, value: Int64, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.setInt(Int(value), for: key)
        
        completion(.success(()))
    }
    
    func globalAttributesSetDouble(key: String, value: Double, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.setDouble(value, for: key)
        
        completion(.success(()))
    }
    
    func globalAttributesSetBool(key: String, value: Bool, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.setBool(value, for: key)
        
        completion(.success(()))
    }
    
    func globalAttributesSetStringList(key: String, value: [String], completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.setArray(AttributeArray.fromStringArray(value), for: key)
        
        completion(.success(()))
    }
    
    func globalAttributesSetIntList(key: String, value: [Int64], completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.setArray(AttributeArray.fromIntArray(value), for: key)
        
        completion(.success(()))
    }
    
    func globalAttributesSetDoubleList(key: String, value: [Double], completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.setArray(AttributeArray.fromDoubleArray(value), for: key)
        
        completion(.success(()))
    }
    
    func globalAttributesSetBoolList(key: String, value: [Bool], completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.globalAttributes.setArray(AttributeArray.fromBoolArray(value), for: key)
        
        completion(.success(()))
    }

    func globalAttributesSetAll(value: GeneratedMutableAttributes, completion: @escaping (Result<Void, any Error>) -> Void) {
        let attributes = SplunkRum.shared.globalAttributes

        value.attributes.forEach { (key, wrapped) in
            switch wrapped {
            case let v as GeneratedMutableAttributeInt:
                attributes.setInt(Int(v.value),for: key)

            case let v as GeneratedMutableAttributeDouble:
                attributes.setDouble(v.value,for: key)

            case let v as GeneratedMutableAttributeString:
                attributes.setString(v.value,for: key)

            case let v as GeneratedMutableAttributeBool:
                attributes.setBool(v.value,for: key)

            case let v as GeneratedMutableAttributeListInt:
                attributes.setArray(AttributeArray.fromIntArray(v.value),for: key)

            case let v as GeneratedMutableAttributeListDouble:
                attributes.setArray(AttributeArray.fromDoubleArray(v.value),for: key)

            case let v as GeneratedMutableAttributeListString:
                attributes.setArray(AttributeArray.fromStringArray(v.value),for: key)

            case let v as GeneratedMutableAttributeListBool:
                attributes.setArray(AttributeArray.fromBoolArray(v.value),for: key)

            case .none:
                break

            default:
                completion(.failure(FlutterError(
                    code: "SET_ALL_FAILED",
                    message:     "Unsupported GeneratedMutableAttribute type for key \(key): \(String(describing: wrapped))",
                    details: nil
                )
                ))
                return
            }
        }

        completion(.success(()))
    }
}
