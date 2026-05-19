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
import android.util.Log
import com.splunk.rum.common.otel.SplunkOpenTelemetrySdk
import com.splunk.rum.integration.okhttp3.manual.OkHttpManualInstrumentation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.InputStream
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val crashAction =
        "com.splunk.rum.flutter.root.exampleapp.root_example_app.INTENTIONAL_CRASH"
    private val badEmailCrashAction =
        "com.splunk.rum.flutter.root.exampleapp.root_example_app.BAD_EMAIL_CRASH"
    private val networkRequestsAction =
        "com.splunk.rum.flutter.root.exampleapp.root_example_app.NETWORK_REQUESTS"
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
        private const val forceFlushTimeoutSeconds = 5L
        private const val processShutdownDelayMillis = 5_000L
        private const val networkTimeoutMillis = 10_000
        private const val defaultNetworkSuccessUrl = "https://example.com/"
        private const val defaultNetworkHttpErrorUrl = "https://httpbin.org/status/500"
        private const val defaultNetworkFailureUrl = "https://127.0.0.1:65534/"

        @Volatile
        private var crashUploadDelayHandlerInstalled = false
    }
}
