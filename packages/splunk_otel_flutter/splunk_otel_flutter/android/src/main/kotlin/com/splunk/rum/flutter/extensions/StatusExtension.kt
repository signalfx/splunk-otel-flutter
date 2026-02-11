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

import com.splunk.rum.flutter.GeneratedStatus
import com.splunk.rum.integration.agent.api.Status

fun GeneratedStatus.toAgentApiStatus(): Status {
    return when (this) {
        GeneratedStatus.RUNNING -> Status.Running
        GeneratedStatus.NOT_INSTALLED -> Status.NotRunning.NotInstalled
        GeneratedStatus.SUB_PROCESS -> Status.NotRunning.Subprocess
        GeneratedStatus.SAMPLED_OUT -> Status.NotRunning.SampledOut
        GeneratedStatus.UNSUPPORTED_OS_VERSION -> Status.NotRunning.UnsupportedOsVersion
        GeneratedStatus.UNSUPPORTED_PLATFORM -> throw IllegalArgumentException("Unsupported GeneratedStatus type for UNSUPPORTED_PLATFORM")
    }
}

fun Status.toGeneratedStatus(): GeneratedStatus {
    return when (this) {
        Status.Running -> GeneratedStatus.RUNNING
        Status.NotRunning.NotInstalled -> GeneratedStatus.NOT_INSTALLED
        Status.NotRunning.SampledOut -> GeneratedStatus.SAMPLED_OUT
        Status.NotRunning.Subprocess -> GeneratedStatus.SUB_PROCESS
        Status.NotRunning.UnsupportedOsVersion -> GeneratedStatus.UNSUPPORTED_OS_VERSION
    }
}