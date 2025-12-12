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