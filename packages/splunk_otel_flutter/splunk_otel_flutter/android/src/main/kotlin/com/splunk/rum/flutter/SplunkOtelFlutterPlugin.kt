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
import com.splunk.rum.integration.agent.api.AgentConfiguration
import com.splunk.rum.integration.agent.api.EndpointConfiguration
import com.splunk.rum.integration.agent.api.SplunkRum
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

        val globalAttributes = MutableAttributes() //TODO after specification

        val agentConfiguration = AgentConfiguration(
            endpoint = EndpointConfiguration(
                realm = agentConfiguration.endpoint.realm,
                rumAccessToken = agentConfiguration.endpoint.rumAccessToken
            ),
            appName = agentConfiguration.appName,
            enableDebugLogging = agentConfiguration.enableDebugLogging,
            deploymentEnvironment = agentConfiguration.deploymentEnvironment,
            //TODO user =  agentConfiguration.user,
            //TODO session = agentConfiguration.session,
            globalAttributes = globalAttributes,
            instrumentedProcessName = agentConfiguration.instrumentedProcessName,
            deferredUntilForeground = agentConfiguration.deferredUntilForeground,
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
            SplunkRum.install(
                application = activity!!.application, //TODO mechanism to check and postpone install
                agentConfiguration = agentConfiguration,
                moduleConfigurations = moduleConfigurations
            )
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("INSTALL_FAILED", e.message)))

            return
        }

        callback(Result.success(Unit))
    }

    override fun sessionReplayStart(callback: (Result<Unit>) -> Unit) {
        SplunkRum.instance.sessionReplay.start();

        callback(Result.success(Unit))
    }

    override fun getSessionId(callback: (Result<String>) -> Unit) {
        callback(Result.success(SplunkRum.instance.session.state.id))
    }
}
