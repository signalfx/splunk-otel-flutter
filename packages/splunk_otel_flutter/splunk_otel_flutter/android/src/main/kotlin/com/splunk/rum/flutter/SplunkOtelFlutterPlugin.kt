package com.splunk.rum.flutter


import android.app.Activity
import android.app.Application
import com.splunk.rum.integration.agent.api.AgentConfiguration
import com.splunk.rum.integration.agent.api.EndpointConfiguration
import com.splunk.rum.integration.agent.api.SplunkRum
import com.splunk.rum.integration.agent.common.attributes.MutableAttributes
import com.splunk.rum.integration.anr.AnrModuleConfiguration
import com.splunk.rum.integration.crash.CrashModuleConfiguration
import com.splunk.rum.integration.httpurlconnection.auto.HttpURLModuleConfiguration
import com.splunk.rum.integration.interactions.InteractionsModuleConfiguration
import com.splunk.rum.integration.navigation.NavigationModuleConfiguration
import com.splunk.rum.integration.navigation.extension.navigation
import com.splunk.rum.integration.networkmonitor.NetworkMonitorModuleConfiguration
import com.splunk.rum.integration.okhttp3.auto.OkHttp3AutoModuleConfiguration
import com.splunk.rum.integration.okhttp3.manual.OkHttp3ManualModuleConfiguration
import com.splunk.rum.integration.sessionreplay.api.RenderingMode
import com.splunk.rum.integration.sessionreplay.extension.sessionReplay
import com.splunk.rum.integration.slowrendering.SlowRenderingModuleConfiguration
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/** SplunkOtelFlutterPlugin */
class SplunkOtelFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    // FlutterPlugin
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "splunk_otel_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // MethodChannel
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" ->
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            else -> result.notImplemented()
        }
    }

    // ActivityAware
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity

        initPlugin(activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        initPlugin(activity)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun initPlugin(activity: Activity?) {
        if (activity == null) return
        SplunkIntegration().install(activity.application)

    }
}


class SplunkIntegration {

    fun install(app: Application) {
        val globalAttributes = MutableAttributes()
        // Uncomment the following to test global attributes
        // globalAttributes["session.id"] = "wrong"
        // globalAttributes["name"] = "John Doe"
        // globalAttributes["age"] = 32
        // globalAttributes["email"] = "john.doe@example.com"
        // globalAttributes["isValid"] = true

        val agent = SplunkRum.install(
            application = app,
            agentConfiguration = AgentConfiguration(
                endpoint = EndpointConfiguration(
                    realm = "",
                    rumAccessToken = ""
                ),
                appName = "Flutter agent app",
                enableDebugLogging = true,
                globalAttributes = globalAttributes,
                deploymentEnvironment = "test-android",
                deferredUntilForeground = true,
                //spanInterceptor = { spanData ->
                //  spanData.toMutableSpanData()
                // }
            ),
            moduleConfigurations = arrayOf(
                InteractionsModuleConfiguration(
                    isEnabled = true
                ),
                NavigationModuleConfiguration(
                    isEnabled = true,
                    isAutomatedTrackingEnabled = true
                ),
                CrashModuleConfiguration(
                    isEnabled = true
                ),
                AnrModuleConfiguration(
                    isEnabled = true
                ),
                HttpURLModuleConfiguration(
                    isEnabled = true,
                    capturedRequestHeaders = listOf("Host", "Accept"),
                    capturedResponseHeaders = listOf("Date", "Content-Type", "Content-Length")
                ),
                OkHttp3AutoModuleConfiguration(
                    isEnabled = true,
                    capturedRequestHeaders = listOf("User-Agent", "Accept"),
                    capturedResponseHeaders = listOf("Date", "Content-Type", "Content-Length")
                ),
                OkHttp3ManualModuleConfiguration(
                    capturedRequestHeaders = listOf("Content-Type", "Accept"),
                    capturedResponseHeaders = listOf("Server", "Content-Type", "Content-Length")
                ),
                NetworkMonitorModuleConfiguration(
                    isEnabled = true
                ),
                SlowRenderingModuleConfiguration(
                    isEnabled = true,
                    //  interval = Duration.ofMillis(500)
                )
            )
        )

        agent.sessionReplay.preferences.renderingMode = RenderingMode.NATIVE
        agent.sessionReplay.start()

        val scheduler = Executors.newSingleThreadScheduledExecutor()

        // Schedule the task to run after 10 seconds
        scheduler.schedule({
            agent.navigation.track("test track")
            agent.globalAttributes.set("platform", "flutter")
            scheduler.shutdown()
        }, 10, TimeUnit.SECONDS)
    }
}
