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

package com.splunk.rum.flutter


import android.app.Activity
import com.splunk.rum.flutter.extensions.toEndpointConfiguration
import com.splunk.rum.flutter.extensions.toGeneratedEndpointConfiguration
import com.splunk.rum.flutter.extensions.toGeneratedMutableAttributes
import com.splunk.rum.flutter.extensions.toGeneratedRecordingMaskList
import com.splunk.rum.flutter.extensions.toGeneratedRenderingMode
import com.splunk.rum.flutter.extensions.toGeneratedSessionReplayStatus
import com.splunk.rum.flutter.extensions.toGeneratedStatus
import com.splunk.rum.flutter.extensions.toGeneratedUserTrackingMode
import com.splunk.rum.flutter.extensions.toMutableAttributes
import com.splunk.rum.flutter.extensions.toRecordingMaskList
import com.splunk.rum.flutter.extensions.toRenderingMode
import com.splunk.rum.flutter.extensions.toUserTrackingMode
import com.splunk.rum.flutter.extensions.wrapIntoGeneratedMutableAttribute
import com.splunk.rum.integration.agent.api.AgentConfiguration
import com.splunk.rum.integration.agent.api.EndpointConfiguration
import com.splunk.rum.integration.agent.api.SplunkRum
import com.splunk.rum.integration.agent.api.session.SessionConfiguration
import com.splunk.rum.integration.agent.api.user.UserConfiguration
import com.splunk.rum.integration.agent.api.user.UserTrackingMode
import com.splunk.rum.integration.agent.common.attributes.MutableAttributes
import com.splunk.rum.integration.navigation.NavigationModuleConfiguration
import com.splunk.rum.integration.sessionreplay.extension.sessionReplay
import com.splunk.rum.integration.slowrendering.SlowRenderingModuleConfiguration
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.time.Duration

/** SplunkOtelFlutterPlugin */
class SplunkOtelFlutterPlugin :
    FlutterPlugin,
    ActivityAware,
    SplunkOtelFlutterHostApi {

    private var activity: Activity? = null

    // FlutterPlugin
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SplunkOtelFlutterHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    // ActivityAware
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun install(
        agentConfiguration: GeneratedAgentConfiguration,
        navigationModuleConfiguration: GeneratedNavigationModuleConfiguration,
        slowRenderingModuleConfiguration: GeneratedSlowRenderingModuleConfiguration,
        callback: (Result<Unit>) -> Unit
    ) {

        val globalAttributes = agentConfiguration.globalAttributes?.toMutableAttributes()

        val agentConfiguration = AgentConfiguration(
            endpoint = agentConfiguration.endpoint.toEndpointConfiguration(),
            appName = agentConfiguration.appName,
            enableDebugLogging = agentConfiguration.enableDebugLogging ?: false,
            deploymentEnvironment = agentConfiguration.deploymentEnvironment,
            user = UserConfiguration(
                trackingMode = agentConfiguration.user?.trackingMode?.toUserTrackingMode() ?: UserTrackingMode.NO_TRACKING
            ),
            session = SessionConfiguration(agentConfiguration.session?.samplingRate ?: 1.0),
            globalAttributes = globalAttributes ?: MutableAttributes(),
            instrumentedProcessName = agentConfiguration.instrumentedProcessName,
            deferredUntilForeground = agentConfiguration.deferredUntilForeground ?: false,
        )

        val moduleConfigurations = arrayOf(
            NavigationModuleConfiguration(
                isEnabled = navigationModuleConfiguration.isEnabled,
                isAutomatedTrackingEnabled = navigationModuleConfiguration.isAutomatedTrackingEnabled,
            ),
            SlowRenderingModuleConfiguration(
                isEnabled = slowRenderingModuleConfiguration.isEnabled,
                interval = Duration.ofMillis((slowRenderingModuleConfiguration.intervalMillis))
            )
        )

        try {
            if(activity == null){
                callback(Result.failure(FlutterError("INSTALL_FAILED", "Activity not available yet")))

                return
            }

            SplunkRum.install(
                application = activity!!.application,
                agentConfiguration = agentConfiguration,
                moduleConfigurations = moduleConfigurations
            )
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("INSTALL_FAILED", e.message)))

            return
        }

        callback(Result.success(Unit))
    }

    // Session replay

    override fun sessionReplayStart(callback: (Result<Unit>) -> Unit) {
        SplunkRum.instance.sessionReplay.start();

        callback(Result.success(Unit))
    }

    override fun sessionReplayStop(callback: (Result<Unit>) -> Unit) {
        SplunkRum.instance.sessionReplay.stop();

        callback(Result.success(Unit))
    }

    override fun sessionReplayStateGetStatus(callback: (Result<GeneratedSessionReplayStatus>) -> Unit) {
        val status = SplunkRum.instance.sessionReplay.state.status

        callback(Result.success(status.toGeneratedSessionReplayStatus()))
    }

    override fun sessionReplayStateGetRenderingMode(callback: (Result<GeneratedRenderingMode>) -> Unit) {
        val renderingMode = SplunkRum.instance.sessionReplay.state.renderingMode

        callback(Result.success(renderingMode.toGeneratedRenderingMode()))
    }

    override fun sessionReplayPreferencesGetRenderingMode(callback: (Result<GeneratedRenderingMode?>) -> Unit) {
        val renderingMode = SplunkRum.instance.sessionReplay.preferences.renderingMode

        callback(Result.success(renderingMode?.toGeneratedRenderingMode()))
    }

    override fun sessionReplayPreferencesSetRenderingMode(
        renderingMode: GeneratedRenderingMode?,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.sessionReplay.preferences.renderingMode = renderingMode?.toRenderingMode()

        callback(Result.success(Unit))
    }

    override fun sessionReplayGetRecordingMask(callback: (Result<GeneratedRecordingMaskList?>) -> Unit) {
        val recordingMask = SplunkRum.instance.sessionReplay.recordingMask

        callback(Result.success(recordingMask?.toGeneratedRecordingMaskList()))
    }

    override fun sessionReplaySetRecordingMask(
        recordingMask: GeneratedRecordingMaskList?,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.sessionReplay.recordingMask = recordingMask?.toRecordingMaskList()

        callback(Result.success(Unit))
    }

    // State

    override fun stateGetAppName(callback: (Result<String>) -> Unit) {
        val appName = SplunkRum.instance.state.appName

        callback(Result.success(appName))
    }

    override fun stateGetAppVersion(callback: (Result<String>) -> Unit) {
        val appVersion = SplunkRum.instance.state.appVersion

        callback(Result.success(appVersion))
    }

    override fun stateGetStatus(callback: (Result<GeneratedStatus>) -> Unit) {
        val status = SplunkRum.instance.state.status

        callback(Result.success(status.toGeneratedStatus()))
    }

    override fun stateGetEndpointConfiguration(callback: (Result<GeneratedEndpointConfiguration>) -> Unit) {
        val endpointConfiguration = SplunkRum.instance.state.endpointConfiguration

        callback(Result.success(endpointConfiguration.toGeneratedEndpointConfiguration()))
    }

    override fun stateGetDeploymentEnvironment(callback: (Result<String>) -> Unit) {
        val deploymentEnvironment = SplunkRum.instance.state.deploymentEnvironment

        callback(Result.success(deploymentEnvironment))
    }

    override fun stateGetIsDebugLoggingEnabled(callback: (Result<Boolean>) -> Unit) {
        val isDebugLoggingEnabled = SplunkRum.instance.state.isDebugLoggingEnabled

        callback(Result.success(isDebugLoggingEnabled))
    }

    override fun stateGetInstrumentedProcessName(callback: (Result<String?>) -> Unit) {
        val instrumentedProcessName = SplunkRum.instance.state.instrumentedProcessName

        callback(Result.success(instrumentedProcessName))
    }

    override fun stateGetDeferredUntilForeground(callback: (Result<Boolean>) -> Unit) {
        val deferredUntilForeground = SplunkRum.instance.state.deferredUntilForeground

        callback(Result.success(deferredUntilForeground))
    }

    // Session

    override fun sessionStateGetId(callback: (Result<String>) -> Unit) {
        val sessionId = SplunkRum.instance.session.state.id

        callback(Result.success(sessionId))
    }

    override fun sessionStateGetSamplingRate(callback: (Result<Double>) -> Unit) {
        val samplingRate = SplunkRum.instance.session.state.samplingRate

        callback(Result.success(samplingRate))
    }

    // User

    override fun userStateGetUserTrackingMode(callback: (Result<GeneratedUserTrackingMode>) -> Unit) {
        val trackingMode = SplunkRum.instance.user.state.trackingMode

        callback(Result.success(trackingMode.toGeneratedUserTrackingMode()))
    }

    override fun userPreferencesGetUserTrackingMode(callback: (Result<GeneratedUserTrackingMode?>) -> Unit) {
        val trackingMode = SplunkRum.instance.user.preferences.trackingMode

        callback(Result.success(trackingMode?.toGeneratedUserTrackingMode()))
    }

    override fun userPreferencesSetUserTrackingMode(
        trackingMode: GeneratedUserTrackingMode,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.user.preferences.trackingMode = trackingMode.toUserTrackingMode()

        callback(Result.success(Unit))
    }

    // Global attributes

    override fun globalAttributesGet(key: String, callback: (Result<Any?>) -> Unit) {
        val attribute = SplunkRum.instance.globalAttributes.get<Any?>(key)
        val convertedAttribute = attribute?.wrapIntoGeneratedMutableAttribute()

        callback(Result.success(convertedAttribute))
    }

    override fun globalAttributesGetAll(callback: (Result<GeneratedMutableAttributes?>) -> Unit) {
        val attributes = SplunkRum.instance.globalAttributes.getAll()
        val convertedAttributes = attributes.toGeneratedMutableAttributes()

        callback(Result.success(convertedAttributes))
    }

    override fun globalAttributesRemove(key: String, callback: (Result<Unit>) -> Unit) {
        SplunkRum.instance.globalAttributes.remove(key)

        callback(Result.success(Unit))
    }

    override fun globalAttributesRemoveAll(callback: (Result<Unit>) -> Unit) {
        SplunkRum.instance.globalAttributes.removeAll()

        callback(Result.success(Unit))
    }

    override fun globalAttributesContains(key: String, callback: (Result<Boolean>) -> Unit) {
        val doesContain = SplunkRum.instance.globalAttributes.contains(key)

        callback(Result.success(doesContain))
    }

    override fun globalAttributesSetString(
        key: String,
        value: String,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.globalAttributes[key] = value

        callback(Result.success(Unit))
    }

    override fun globalAttributesSetInt(key: String, value: Long, callback: (Result<Unit>) -> Unit) {
        SplunkRum.instance.globalAttributes[key] = value

        callback(Result.success(Unit))
    }

    override fun globalAttributesSetDouble(
        key: String,
        value: Double,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.globalAttributes[key] = value

        callback(Result.success(Unit))
    }

    override fun globalAttributesSetBool(
        key: String,
        value: Boolean,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.globalAttributes[key] = value

        callback(Result.success(Unit))
    }

    override fun globalAttributesSetStringList(
        key: String,
        value: List<String>,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.globalAttributes.update {
            put(key, *value.toTypedArray())
        }

        callback(Result.success(Unit))
    }

    override fun globalAttributesSetIntList(
        key: String,
        value: List<Long>,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.globalAttributes.update {
            put(key, *value.toLongArray())
        }

        callback(Result.success(Unit))
    }

    override fun globalAttributesSetDoubleList(
        key: String,
        value: List<Double>,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.globalAttributes.update {
            put(key, *value.toDoubleArray())
        }

        callback(Result.success(Unit))
    }

    override fun globalAttributesSetBoolList(
        key: String,
        value: List<Boolean>,
        callback: (Result<Unit>) -> Unit
    ) {
        SplunkRum.instance.globalAttributes.update {
            put(key, *value.toBooleanArray())
        }

        callback(Result.success(Unit))
    }

    override fun globalAttributesSetAll(
        value: GeneratedMutableAttributes,
        callback: (Result<Unit>) -> Unit
    ) {
        try {
            SplunkRum.instance.globalAttributes.setAll(value.toMutableAttributes())
        }catch (e:Exception)
        {
            callback(Result.failure(FlutterError("SET_ALL_FAILED", e.message)))

            return
        }

        callback(Result.success(Unit))
    }
}
