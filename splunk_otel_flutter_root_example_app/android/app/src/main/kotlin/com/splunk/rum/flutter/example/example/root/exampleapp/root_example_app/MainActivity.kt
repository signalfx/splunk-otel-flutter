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

package com.splunk.rum.flutter.root.exampleapp.root_example_app

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import com.splunk.rum.common.otel.SplunkOpenTelemetrySdk
import com.splunk.rum.integration.agent.api.SplunkRum
import com.splunk.rum.integration.customtracking.extension.customTracking
import com.splunk.rum.integration.okhttp3.manual.OkHttpManualInstrumentation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.trace.Span
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.InputStream
import java.time.Instant
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val crashAction =
        "com.splunk.rum.flutter.root.exampleapp.root_example_app.INTENTIONAL_CRASH"
    private val badEmailCrashAction =
        "com.splunk.rum.flutter.root.exampleapp.root_example_app.BAD_EMAIL_CRASH"
    private val networkRequestsAction =
        "com.splunk.rum.flutter.root.exampleapp.root_example_app.NETWORK_REQUESTS"
    private val appErrorsAction =
        "com.splunk.rum.flutter.root.exampleapp.root_example_app.APP_ERRORS"
    private var hotStartupSpan: Span? = null
    private var hotStartupStartElapsedMillis = 0L
    private var hotStartupStartWallClockMillis = 0L
    private val okHttpClient = OkHttpClient.Builder()
        .callTimeout(networkTimeoutMillis.toLong(), TimeUnit.MILLISECONDS)
        .build()

    override fun onCreate(savedInstanceState: Bundle?) {
        installCrashUploadDelayHandler()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "splunk_otel_flutter_root_example_app/crash"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "crash" -> {
                    triggerBadEmailCrash()
                }
                "anr" -> {
                    val blockMillis = call.argument<Int>("blockMillis")?.toLong() ?: 15_000L
                    Thread.sleep(blockMillis)
                    result.success(null)
                }
                "networkRequests" -> {
                    val urls = call.argument<List<String>>("urls").orEmpty()
                    if (urls.isEmpty()) {
                        result.error(
                            "missing_urls",
                            "At least one URL is required.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    runNetworkRequests(urls) { responses ->
                        result.success(responses)
                    }
                }
                "appErrors" -> {
                    val count = call.argument<Int>("count") ?: defaultAppErrorCount
                    triggerAppErrors(count)
                    result.success(count)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installCrashUploadDelayHandler() {
        if (crashUploadDelayHandlerInstalled) return

        crashUploadDelayHandlerInstalled = true
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler(
            CrashUploadDelayHandler(defaultHandler),
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }

    override fun onRestart() {
        super.onRestart()
        startHotStartupWorkflow()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            finishHotStartupWorkflow()
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == crashAction) {
            intent.action = null
            Handler(Looper.getMainLooper()).post {
                throw RuntimeException("Intentional native crash from adb intent")
            }
        } else if (intent?.action == badEmailCrashAction) {
            intent.action = null
            triggerBadEmailCrash()
        } else if (intent?.action == networkRequestsAction) {
            intent.action = null
            triggerNetworkRequests(intent)
        } else if (intent?.action == appErrorsAction) {
            intent.action = null
            triggerAppErrors(intent.getIntExtra("app_error_count", defaultAppErrorCount))
        }
    }

    private fun triggerBadEmailCrash() {
        Handler(Looper.getMainLooper()).post {
            throw RuntimeException("Intentional native crash from login screen invalid email")
        }
    }

    private fun triggerNetworkRequests(intent: Intent) {
        val urls = listOf(
            intent.getStringExtra("network_success_url") ?: defaultNetworkSuccessUrl,
            intent.getStringExtra("network_http_error_url") ?: defaultNetworkHttpErrorUrl,
            intent.getStringExtra("network_failure_url") ?: defaultNetworkFailureUrl,
        )

        Log.d(networkTag, "Starting network diagnostics from Android intent")
        runNetworkRequests(urls) { responses ->
            Log.d(networkTag, "Network diagnostics completed responses=$responses")
        }
    }

    private fun triggerAppErrors(count: Int) {
        Thread {
            val boundedCount = count.coerceIn(1, maxAppErrorCount)
            Log.d(appErrorTag, "Reporting $boundedCount handled app errors")

            repeat(boundedCount) { index ->
                val error = IllegalStateException(
                    "Intentional handled app error ${index + 1} from telemetry test",
                )
                val attributes = Attributes.builder()
                    .put("test.name", "app_errors")
                    .put("app_error.sequence", (index + 1).toLong())
                    .put("app_error.handled", true)
                    .put("app_error.source", "android.intent")
                    .build()

                SplunkRum.instance.addRumException(error, attributes)
                Log.d(appErrorTag, "Reported handled app error ${index + 1}")
            }

            forceFlushTelemetry("app errors")
        }.start()
    }

    private fun runNetworkRequests(
        urls: List<String>,
        onComplete: ((List<Map<String, Any?>>) -> Unit)? = null,
    ) {
        Thread {
            val responses = urls.map { performNetworkRequest(it) }
            forceFlushTelemetry("network diagnostics")
            Handler(Looper.getMainLooper()).post {
                onComplete?.invoke(responses)
            }
        }.start()
    }

    private fun performNetworkRequest(urlString: String): Map<String, Any?> {
        val startedAt = System.currentTimeMillis()

        return try {
            val request = Request.Builder()
                .url(urlString)
                .get()
                .header("Accept", "application/json, text/plain;q=0.8")
                .header("User-Agent", "SplunkCinemaNetworkDiagnostics/1.0")
                .header("X-Splunk-RUM-Test", "network-requests")
                .build()

            OkHttpManualInstrumentation.instance
                .buildOkHttpCallFactory(okHttpClient)
                .newCall(request)
                .execute()
                .use { response ->
                response.body?.byteStream()?.use { it.drain() }
                val statusCode = response.code

                val durationMillis = System.currentTimeMillis() - startedAt
                Log.d(
                    networkTag,
                    "OkHttp request finished url=$urlString status=$statusCode durationMs=$durationMillis",
                )

                mapOf(
                    "url" to urlString,
                    "statusCode" to statusCode,
                    "durationMillis" to durationMillis,
                    "succeeded" to (statusCode in 200..399),
                )
            }
        } catch (throwable: Throwable) {
            val durationMillis = System.currentTimeMillis() - startedAt
            Log.w(
                networkTag,
                "OkHttp request failed url=$urlString durationMs=$durationMillis",
                throwable,
            )

            mapOf(
                "url" to urlString,
                "durationMillis" to durationMillis,
                "succeeded" to false,
                "errorType" to throwable.javaClass.name,
                "errorMessage" to throwable.message,
            )
        }
    }

    private fun InputStream.drain() {
        val buffer = ByteArray(1024)
        while (read(buffer) != -1) {
            // Drain the response body so OkHttp completes the call cleanly.
        }
    }

    private fun forceFlushTelemetry(reason: String) {
        try {
            Log.d(networkTag, "Force flushing telemetry after $reason")
            val tracerProvider = SplunkOpenTelemetrySdk.instance?.sdkTracerProvider ?: return
            tracerProvider.forceFlush().join(forceFlushTimeoutSeconds, TimeUnit.SECONDS)
        } catch (throwable: Throwable) {
            Log.w(networkTag, "Telemetry force flush failed after $reason", throwable)
        }
    }

    private fun startHotStartupWorkflow() {
        if (hotStartupSpan != null) return

        hotStartupStartElapsedMillis = SystemClock.elapsedRealtime()
        hotStartupStartWallClockMillis = System.currentTimeMillis()
        hotStartupSpan = try {
            SplunkRum.instance.customTracking.trackWorkflow("HotStartup")
        } catch (throwable: Throwable) {
            Log.w(startupTag, "Failed to start custom hot-start workflow", throwable)
            null
        }

        hotStartupSpan?.setAttribute("component", "appstart")
        hotStartupSpan?.setAttribute("start.type", "hot")
        hotStartupSpan?.setAttribute("workflow.name", "HotStartup")
        hotStartupSpan?.setAttribute("startup.source", "android.onRestart")
        Log.d(startupTag, "Custom hot-start workflow started")
    }

    private fun finishHotStartupWorkflow() {
        val span = hotStartupSpan ?: return
        hotStartupSpan = null

        val durationMillis = SystemClock.elapsedRealtime() - hotStartupStartElapsedMillis
        span.setAttribute("hot_startup.duration_ms", durationMillis)
        span.setAttribute("startup.duration_ms", durationMillis)
        span.setAttribute("startup.end_signal", "window_focus")
        span.end()

        Log.d(startupTag, "Custom hot-start workflow ended durationMs=$durationMillis")
        reportHotStartupAppStartSpan(durationMillis)
        forceFlushTelemetry("hot startup")
    }

    private fun reportHotStartupAppStartSpan(durationMillis: Long) {
        try {
            val tracerProvider = SplunkOpenTelemetrySdk.instance?.sdkTracerProvider ?: return
            val endWallClockMillis = hotStartupStartWallClockMillis + durationMillis
            val span = tracerProvider
                .get("SplunkRum")
                .spanBuilder("AppStart")
                .setStartTimestamp(hotStartupStartWallClockMillis, TimeUnit.MILLISECONDS)
                .startSpan()

            span.setAttribute("component", "appstart")
            span.setAttribute("screen.name", "unknown")
            span.setAttribute("start.type", "hot")
            span.end(Instant.ofEpochMilli(endWallClockMillis))

            Log.d(startupTag, "Synthetic AppStart hot span ended durationMs=$durationMillis")
        } catch (throwable: Throwable) {
            Log.w(startupTag, "Failed to report synthetic AppStart hot span", throwable)
        }
    }

    private class CrashUploadDelayHandler(
        private val delegate: Thread.UncaughtExceptionHandler?,
    ) : Thread.UncaughtExceptionHandler {
        override fun uncaughtException(thread: Thread, throwable: Throwable) {
            try {
                Log.d(tag, "Force flushing crash span before process shutdown")
                forceFlushSplunkTracer()
                Thread.sleep(processShutdownDelayMillis)
            } catch (flushError: Throwable) {
                Log.w(tag, "Crash span force flush failed", flushError)
            } finally {
                delegate?.uncaughtException(thread, throwable)
            }
        }

        private fun forceFlushSplunkTracer() {
            val sdkClass = Class.forName("com.splunk.rum.common.otel.SplunkOpenTelemetrySdk")
            val sdkObject = sdkClass.getField("INSTANCE").get(null)
            val openTelemetrySdk = sdkClass.getMethod("getInstance").invoke(sdkObject) ?: return
            val tracerProvider = openTelemetrySdk.javaClass
                .getMethod("getSdkTracerProvider")
                .invoke(openTelemetrySdk) ?: return
            val flushResult = tracerProvider.javaClass
                .getMethod("forceFlush")
                .invoke(tracerProvider) ?: return

            flushResult.javaClass
                .getMethod("join", Long::class.javaPrimitiveType, TimeUnit::class.java)
                .invoke(flushResult, forceFlushTimeoutSeconds, TimeUnit.SECONDS)
        }
    }

    companion object {
        private const val tag = "CrashUploadDelay"
        private const val networkTag = "NetworkDiagnostics"
        private const val startupTag = "HotStartupDiagnostics"
        private const val appErrorTag = "AppErrorDiagnostics"
        private const val forceFlushTimeoutSeconds = 5L
        private const val processShutdownDelayMillis = 5_000L
        private const val networkTimeoutMillis = 10_000
        private const val defaultAppErrorCount = 3
        private const val maxAppErrorCount = 20
        private const val defaultNetworkSuccessUrl = "https://example.com/"
        private const val defaultNetworkHttpErrorUrl = "https://httpbin.org/status/500"
        private const val defaultNetworkFailureUrl = "https://127.0.0.1:65534/"

        @Volatile
        private var crashUploadDelayHandlerInstalled = false
    }
}
