package com.splunk.rum.flutter.example

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.splunk.rum.flutter.example/anr"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "simulateANR" -> {
                    simulateANR()
                    result.success("ANR simulated")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun simulateANR() {
        val ANR_TIMEOUT_DURATION = 10_000L // 10 seconds
        try {
            Thread.sleep(ANR_TIMEOUT_DURATION)
        } catch (e: InterruptedException) {
            throw RuntimeException(e)
        }
    }
}