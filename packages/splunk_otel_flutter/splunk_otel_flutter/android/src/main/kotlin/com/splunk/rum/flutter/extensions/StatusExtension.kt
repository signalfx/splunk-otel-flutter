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