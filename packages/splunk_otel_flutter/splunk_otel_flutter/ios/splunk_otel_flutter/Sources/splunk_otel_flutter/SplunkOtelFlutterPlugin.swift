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
@_spi(SplunkInternal) import SplunkAgent
import OpenTelemetryApi
import SplunkSlowFrameDetector
import SplunkNavigation
import SplunkAppStart
import SplunkNetwork
import SplunkInteractions
import SplunkNetworkMonitor
import SplunkCrashReports

extension FlutterError: Error {}

public class SplunkOtelFlutterPlugin: NSObject, FlutterPlugin, SplunkOtelFlutterHostApi {
    
    private var didFinishLaunchingAt: Date?
    private var willEnterForegroundAt: Date?
    private var workflowSpans: [Int64: (span: Span, startTime: Int64)] = [:]
    private var workflowHandleCounter: Int64 = 0
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SplunkOtelFlutterPlugin()
        
        // Observe lifecycle notifications
           NotificationCenter.default.addObserver(
               instance,
               selector: #selector(onDidBecomeActive),
               name: UIApplication.didBecomeActiveNotification,
               object: nil
           )

           NotificationCenter.default.addObserver(
               instance,
               selector: #selector(onDidFinishLaunchingNotification),
               name: UIApplication.didFinishLaunchingNotification,
               object: nil
           )

           NotificationCenter.default.addObserver(
               instance,
               selector: #selector(onWillEnterForeground),
               name: UIApplication.willEnterForegroundNotification,
               object: nil
           )
        
        SplunkOtelFlutterHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification handlers
    @objc private func onDidFinishLaunchingNotification(_ note: Notification) {
        let launchOptions = note.userInfo as? [UIApplication.LaunchOptionsKey: Any]
        handleDidFinishLaunching(launchOptions: launchOptions)
    }
    
    @objc private func onDidBecomeActive(_ note: Notification) {
        handleDidBecomeActive()
    }
    
    @objc private func onWillEnterForeground(_ note: Notification) {
          handleWillEnterForeground()
      }
    
    // MARK: - Internals
    private func handleDidFinishLaunching(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        didFinishLaunchingAt = Date()
    }

    private func handleWillEnterForeground() {
        // Mark the moment the app transitions toward foreground (warm start path)
        willEnterForegroundAt = Date()
    }
    
 

    private func handleDidBecomeActive() {
        // The "active" moment (common for both cold and warm starts)
        let becameActiveAt = Date()

        // Send app start timing to Splunk RUM.
        // - didFinishLaunchingAt: non-nil indicates a cold start path
        // - willEnterForegroundAt: non-nil indicates a warm start path
        // Splunk RUM will infer the correct variant based on which timestamps are provided.
        SplunkRum.shared.appStart.track(
            didBecomeActive: becameActiveAt,
            didFinishLaunching: didFinishLaunchingAt,
            willEnterForeground: willEnterForegroundAt
        )


        // Clear foreground marker so a later activation (e.g., another background->foreground) is measured correctly.
        willEnterForegroundAt = nil
    }
    
    func install(agentConfiguration: GeneratedAgentConfiguration,
                 navigationModuleConfiguration: GeneratedNavigationModuleConfiguration?,
                 slowRenderingModuleConfiguration: GeneratedSlowRenderingModuleConfiguration?,
                 crashReportsModuleConfiguration: GeneratedCrashReportsModuleConfiguration?,
                 interactionsModuleConfiguration: GeneratedInteractionsModuleConfiguration?,
                 networkMonitorModuleConfiguration: GeneratedNetworkMonitorModuleConfiguration?,
                 applicationLifecycleModuleConfiguration: GeneratedApplicationLifecycleModuleConfiguration?,
                 // Android-only
                 anrModuleConfiguration: GeneratedAnrModuleConfiguration?, 
                 httpUrlModuleConfiguration: GeneratedHttpUrlModuleConfiguration?, 
                 okHttp3AutoModuleConfiguration: GeneratedOkHttp3AutoModuleConfiguration?, 
                 // iOS-only
                 networkInstrumentationModuleConfiguration: GeneratedNetworkInstrumentationModuleConfiguration?,
                 completion: @escaping (Result<Void, any Error>) -> Void) {
        
        
        // should be always not nil
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
        
     
        let mergedGlobalAttributes =
            agentConfiguration.globalAttributes?.toMutableAttributes() ?? MutableAttributes()
        //TODO move to Resources later
        mergedGlobalAttributes.setString(
            SplunkRumFlutterTelemetryVersions.rumSdkFlutterVersion,
            for: SplunkRumFlutterTelemetryAttributeKeys.rumSdkFlutterVersion)

        let agentConfig = AgentConfiguration(
            endpoint: endpointConfiguration,
            appName: agentConfiguration.appName,
            deploymentEnvironment: agentConfiguration.deploymentEnvironment,
        )
            .appVersion(agentConfiguration.appVersion ?? "")
            .enableDebugLogging(agentConfiguration.enableDebugLogging ?? false)
            .globalAttributes(mergedGlobalAttributes)
            .sessionConfiguration(SessionConfiguration(samplingRate: agentConfiguration.session?.samplingRate ?? 1.0))
            .userConfiguration(UserConfiguration(trackingMode: agentConfiguration.user?.trackingMode == .anonymousTracking ? .anonymousTracking : .noTracking))
        do {
            let moduleConfigurations: [Any] = [
                   slowRenderingModuleConfiguration.map {
                       SlowFrameDetectorConfiguration(isEnabled: $0.isEnabled)
                   },
                   navigationModuleConfiguration.map {
                       NavigationConfiguration(
                           isEnabled: $0.isEnabled,
                           enableAutomatedTracking: $0.isAutomatedTrackingEnabled
                       )
                   },
                   networkInstrumentationModuleConfiguration.map {
                       let ignoredUrls = (try? $0.ignoreURLs.toIgnoreURLs()) ?? IgnoreURLs()
                       return NetworkInstrumentationConfiguration(
                           isEnabled: $0.isEnabled,
                           ignoreURLs: ignoredUrls
                       )
                   },
                   crashReportsModuleConfiguration.map {
                       CrashReportsConfiguration(
                           isEnabled: $0.isEnabled,
                       )
                   },
                   interactionsModuleConfiguration.map {
                       InteractionsConfiguration(
                           isEnabled: $0.isEnabled,
                       )
                   },
                   networkMonitorModuleConfiguration.map {
                       NetworkMonitorConfiguration(
                           isEnabled: $0.isEnabled,
                       )
                   },
               ].compactMap { $0 }// removes nils automatically
            
            let agent = try SplunkRum.install(with: agentConfig, moduleConfigurations: moduleConfigurations)
          
            handleDidBecomeActive()
            
            completion(.success(()))
        } catch {
            completion(.failure(
                FlutterError(
                    code: "INSTALL_FAILED",
                    message: error.localizedDescription,
                    details: nil
                )
            ))
        }
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
    
    // MARK: - Preferences
    
    func preferencesGetEndpointConfiguration(completion: @escaping (Result<GeneratedEndpointConfiguration?, any Error>) -> Void) {
        //TODO
        
        //let endpointConfiguration = SplunkRum.shared.
        
        //completion(.success(endpointConfiguration?.toGeneratedEndpointConfiguration()))
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
    
    // MARK: - Custom tracking
    
    func customTrackingTrackCustomEvent(name: String, attributes: GeneratedMutableAttributes, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.customTracking.trackCustomEvent(name, attributes.toMutableAttributes())
        
        completion(.success(()))
    }
    
    func customTrackingStartWorkflow(workflowName: String, completion: @escaping (Result<Int64, any Error>) -> Void) {
        // Start the workflow and generate a unique handle
        let span = SplunkRum.shared.customTracking.trackWorkflow(workflowName)
        let startTime = Int64(Date().timeIntervalSince1970 * 1000)
        
        workflowHandleCounter += 1
        let handle = workflowHandleCounter
        
        workflowSpans[handle] = (span: span, startTime: startTime)
        
        completion(.success(handle))
    }
    
    func customTrackingEndWorkflow(handle: Int64, completion: @escaping (Result<Void, any Error>) -> Void) {
        guard let workflow = workflowSpans[handle] else {
            completion(.failure(NSError(domain: "SplunkOtelFlutter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid workflow handle"])))
            return
        }
        
        // End the workflow
        let endTime = Int64(Date().timeIntervalSince1970 * 1000)
        
        workflow.span.setAttribute(key: "workflow.start.time", value: AttributeValue.int(Int(workflow.startTime)))
        workflow.span.setAttribute(key: "workflow.end.time", value: AttributeValue.int(Int(endTime)))
        workflow.span.end()
        
        workflowSpans.removeValue(forKey: handle)
        
        completion(.success(()))
    }
    
    // MARK: - Navigation
    
    func navigationTrack(screenName: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        SplunkRum.shared.navigation.track(screen: screenName)
        
        completion(.success(()))
    }
}
