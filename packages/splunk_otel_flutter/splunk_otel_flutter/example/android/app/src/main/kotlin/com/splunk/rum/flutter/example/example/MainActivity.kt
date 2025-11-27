package com.splunk.rum.flutter.example

import android.graphics.Color

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.splunk.rum.flutter.example.example.simulations.SlowRendering.FROZEN_REFRESH_INTERVAL_MS
import com.splunk.rum.flutter.example.example.simulations.SlowRendering.FROZEN_RENDER_DELAY_MS
import com.splunk.rum.flutter.example.example.simulations.SlowRendering.SLOW_RENDER_DELAY_MS
import com.splunk.rum.flutter.example.example.simulations.SlowRendering.simulateSlowRendering
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import kotlin.random.Random

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.splunk.rum.flutter.example"
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "simulateANR" -> {
                    simulateANR()

                    result.success("ANR simulated")
                }
                "simulateSlowRender" -> {
                    simulateSlowRender()

                    result.success("slow render simulated")
                }
                "simulateFrozenRender"-> {
                    simulateFrozenRender()

                    result.success("frozen render simulated")

                }
                "testOkHttpGet" -> {
                    val url = call.argument<String>("url") ?: "https://httpbin.org/get"
                    doOkHttpGet(url) {

                    }
                    result.success("okhttpGet started")
                }
                "testHttpUrlConnectionGet" -> {
                    val url = call.argument<String>("url") ?: "https://httpbin.org/get"
                    doHttpUrlConnectionGet(url) {

                    }
                    result.success("httpUrlConnectionGet started")
                }
                "simulateCrash" -> {
                    Handler(Looper.getMainLooper()).post {
                        throw RuntimeException("Test crash triggered from Flutter method channel (Android)")
                    }
                    // We won't reach here, but keep the signature happy:
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun doOkHttpGet(url: String, emit: (Map<String, Any?>) -> Unit) {
        Log.d("splunk_otel_flutter","started okHttp")

        DummyNetworkClient.callRandomEndpoint()
    }


    private fun doHttpUrlConnectionGet(urlStr: String, emit: (Map<String, Any?>) -> Unit) {


        executeGet("https://httpbin.org/status/201")

    }

    private fun String.openHttpConnection(): HttpURLConnection = URL(this).openConnection() as HttpURLConnection

    private val Int.isSuccessful: Boolean
        get() = this in 200..299

    private fun executeGet(
        inputUrl: String,
        getInputStream: Boolean = true,
        disconnect: Boolean = true,
        stallRequest: Boolean = false
    ) {
        runOnBackgroundThread {
            var connection: HttpURLConnection? = null
            try {
                connection = inputUrl.openHttpConnection()
                connection.setRequestProperty("Accept", "application/json")

                val responseCode = connection.responseCode
                val responseMessage = connection.responseMessage

                val responseBody = if (responseCode.isSuccessful && getInputStream) {
                    connection.inputStream.bufferedReader().use { it.readText() }
                } else {
                    connection.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
                }

                if (stallRequest) {
                    Thread.sleep(STALL_DURATION_MS)
                }

                Log.d("splunk_otel_flutter","xxxxxxxxx HttpUrlConnection done ")

                Log.v(
            "splunk_otel_flutter",
                    "response code: $responseCode response message: $responseMessage response body: $responseBody"
                )
            } catch (e: Exception) {
                Log.d("splunk_otel_flutter","xxxxxxxxx  HttpUrlConnection failed ")
                e.printStackTrace()
            } finally {
                if (disconnect) {
                    connection?.disconnect()
                }
            }
        }
    }


    private fun simulateANR() {
        val anrTimeoutDuration = 10_000L
        Thread.sleep(anrTimeoutDuration)
    }

    /**
     * Starts a simulation of slow rendering with short frame delays.
     */
    private fun simulateSlowRender() = simulateSlowRendering(
        activity = this,
        renderDelayMs = SLOW_RENDER_DELAY_MS,
        color = Color.BLUE,
    )



    /**
     * Starts a simulation of frozen rendering with long frame delays.
     */
    private fun simulateFrozenRender() = simulateSlowRendering(
        activity = this,
        renderDelayMs = FROZEN_RENDER_DELAY_MS,
        color = Color.RED,
        refreshIntervalMs = FROZEN_REFRESH_INTERVAL_MS
    )



    fun runOnBackgroundThread(
        name: String = "BackgroundWorker",
        uncaughtExceptionHandler: Thread.UncaughtExceptionHandler? = null,
        block: () -> Unit
    ): Thread {
        val thread = Thread(block, name)
        thread.uncaughtExceptionHandler = uncaughtExceptionHandler
        thread.start()
        return thread
    }

    companion object {
        private const val STALL_DURATION_MS = 20_000L
    }
}

object DummyNetworkClient {

    private const val TAG = "DummyNetworkClient"
    private val client = OkHttpClient()
    private val executor = Executors.newSingleThreadExecutor()

    /** Public entry point for triggering a random dummy network call. */
    fun callRandomEndpoint() {
        executor.execute {
            val request = createRandomRequest()
            executeRequest(request)
        }
    }

    /** Chooses and builds a random request. */
    private fun createRandomRequest(): Request {
        return when (Random.nextInt(3)) {
            0 -> buildHelloWorldRequest()
            1 -> build404Request()
            else -> buildMarkdownPostRequest()
        }
    }

    /** Executes the given request and logs the result or failure. */
    private fun executeRequest(request: Request) {
        runCatching {
            client.newCall(request).execute().use { response ->
                Log.d(TAG, "Dummy call to ${request.url} finished with code ${response.code}")
            }
        }.onFailure {
            Log.w(TAG, "Dummy call to ${request.url} failed", it)
        }
    }

    /** Builds a request to a simple text endpoint. */
    private fun buildHelloWorldRequest(): Request {
        Log.d("splunk_otel_flutter","requrest")

        return Request.Builder()
            .url("https://publicobject.com/helloworld.txt")
            .get()
            .addCommonHeaders()
            .build()
    }

    /** Builds a request that intentionally triggers a 404. */
    private fun build404Request(): Request {
        return Request.Builder()
            .url("https://httpbin.org/status/404")
            .get()
            .addCommonHeaders()
            .build()
    }

    /** Builds a POST request to GitHub's markdown endpoint. */
    private fun buildMarkdownPostRequest(): Request {
        val markdown = """
            # Splunk Cinema
            *Simulated favorite action from the Android demo.*
        """.trimIndent()
        return Request.Builder()
            .url("https://api.github.com/markdown/raw")
            .post(markdown.toRequestBody("text/plain; charset=utf-8".toMediaType()))
            .addCommonHeaders()
            .header("Content-Type", "text/plain; charset=utf-8")
            .build()
    }

    /** Adds a consistent set of headers to all requests. */
    private fun Request.Builder.addCommonHeaders(): Request.Builder {
        return header("User-Agent", "SplunkCinema/1.0 (Android)")
            .header("Accept", "application/json, text/plain;q=0.8")
            .header("Accept-Language", "en-US")
            .header("Cache-Control", "no-cache")
    }
}

