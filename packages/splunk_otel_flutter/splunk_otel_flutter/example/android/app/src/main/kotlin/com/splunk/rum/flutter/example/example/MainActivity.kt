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