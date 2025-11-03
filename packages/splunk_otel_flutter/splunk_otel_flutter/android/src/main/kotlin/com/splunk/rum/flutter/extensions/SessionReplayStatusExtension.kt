package com.splunk.rum.flutter.extensions

import com.splunk.rum.flutter.GeneratedSessionReplayStatus
import com.splunk.rum.integration.sessionreplay.api.Status

fun Status.toGeneratedSessionReplayStatus(): GeneratedSessionReplayStatus {
    return when (this) {
        is Status.Recording -> GeneratedSessionReplayStatus.IS_RECORDING
        is Status.NotRecording -> {
            when (this.cause) {
                Status.NotRecording.Cause.NOT_STARTED -> GeneratedSessionReplayStatus.NOT_STARTED
                Status.NotRecording.Cause.STOPPED -> GeneratedSessionReplayStatus.STOPPED
                Status.NotRecording.Cause.BELOW_MIN_SDK_VERSION -> GeneratedSessionReplayStatus.BELOW_MIN_SDK_VERSION
                Status.NotRecording.Cause.STORAGE_LIMIT_REACHED -> GeneratedSessionReplayStatus.STORAGE_LIMIT_REACHED
                Status.NotRecording.Cause.INTERNAL_ERROR -> GeneratedSessionReplayStatus.INTERNAL_ERROR
            }
        }
    }
}