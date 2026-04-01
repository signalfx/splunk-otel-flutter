/*
 * Copyright 2026 Splunk Inc.
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

package com.splunk.rum.flutter.sessionreplay.splunk_otel_flutter_session_replay

import com.splunk.rum.flutter.sessionreplay.GeneratedRecordingMaskList
import com.splunk.rum.flutter.sessionreplay.GeneratedRenderingMode
import com.splunk.rum.flutter.sessionreplay.GeneratedSessionReplayStatus
import com.splunk.rum.flutter.sessionreplay.SplunkOtelFlutterSessionReplayHostApi
import com.splunk.rum.flutter.sessionreplay.splunk_otel_flutter_session_replay.extensions.toGeneratedRecordingMaskList
import com.splunk.rum.flutter.sessionreplay.splunk_otel_flutter_session_replay.extensions.toGeneratedRenderingMode
import com.splunk.rum.flutter.sessionreplay.splunk_otel_flutter_session_replay.extensions.toGeneratedSessionReplayStatus
import com.splunk.rum.flutter.sessionreplay.splunk_otel_flutter_session_replay.extensions.toRecordingMaskList
import com.splunk.rum.flutter.sessionreplay.splunk_otel_flutter_session_replay.extensions.toRenderingMode
import com.splunk.rum.integration.agent.api.SplunkRum
import com.splunk.rum.integration.sessionreplay.extension.sessionReplay
import io.flutter.embedding.engine.plugins.FlutterPlugin

class SplunkOtelFlutterSessionReplayPlugin :
    FlutterPlugin,
    SplunkOtelFlutterSessionReplayHostApi {

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SplunkOtelFlutterSessionReplayHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SplunkOtelFlutterSessionReplayHostApi.setUp(binding.binaryMessenger, null)
    }

    override fun sessionReplayStart(callback: (Result<Unit>) -> Unit) {
        SplunkRum.instance.sessionReplay.start()

        callback(Result.success(Unit))
    }

    override fun sessionReplayStop(callback: (Result<Unit>) -> Unit) {
        SplunkRum.instance.sessionReplay.stop()

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
}
