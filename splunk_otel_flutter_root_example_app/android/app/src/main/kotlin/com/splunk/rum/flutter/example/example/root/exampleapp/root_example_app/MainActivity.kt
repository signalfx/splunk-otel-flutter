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

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.system.exitProcess

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "RootExampleMainActivity"
        private const val NATIVE_CRASH_CHANNEL =
            "com.splunk.rum.flutter.root.exampleapp/native_crash"
        private const val CRASH_MESSAGE = "Test crash triggered from root example app"

        @Volatile
        private var crashUploadGraceInstalled = false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NATIVE_CRASH_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installCrashUploadGrace" -> {
                    val seconds = call.argument<Int>("seconds") ?: 0
                    installCrashUploadGrace(seconds)
                    result.success(null)
                }
                "simulateCrash" -> {
                    triggerIntentionalCrash()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installCrashUploadGrace(seconds: Int) {
        if (seconds <= 0 || crashUploadGraceInstalled) {
            return
        }

        val sleepMillis = seconds.coerceAtMost(30).toLong() * 1000L
        val previousHandler = Thread.getDefaultUncaughtExceptionHandler()

        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                Log.d(
                    TAG,
                    "Waiting ${sleepMillis}ms before final crash handling so RUM crash data can upload."
                )
                Thread.sleep(sleepMillis)
            } catch (interrupted: InterruptedException) {
                Thread.currentThread().interrupt()
            }

            if (previousHandler != null) {
                previousHandler.uncaughtException(thread, throwable)
            } else {
                Log.e(TAG, "Unhandled exception after crash upload grace.", throwable)
                android.os.Process.killProcess(android.os.Process.myPid())
                exitProcess(10)
            }
        }

        crashUploadGraceInstalled = true
        Log.d(TAG, "Installed crash upload grace handler for ${seconds}s.")
    }

    private fun triggerIntentionalCrash() {
        if (crashUploadGraceInstalled) {
            Thread {
                throw RuntimeException(CRASH_MESSAGE)
            }.apply {
                name = "intentional-crash-thread"
                start()
            }
            return
        }

        Handler(Looper.getMainLooper()).post {
            throw RuntimeException(CRASH_MESSAGE)
        }
    }
}
