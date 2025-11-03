package com.splunk.rum.flutter.extensions

import com.splunk.rum.flutter.GeneratedUserTrackingMode
import com.splunk.rum.integration.agent.api.user.UserTrackingMode

fun GeneratedUserTrackingMode.toUserTrackingMode(): UserTrackingMode {
    return when (this) {
        GeneratedUserTrackingMode.NO_TRACKING -> UserTrackingMode.NO_TRACKING
        GeneratedUserTrackingMode.ANONYMOUS_TRACKING -> UserTrackingMode.ANONYMOUS_TRACKING
    }
}

fun UserTrackingMode.toGeneratedUserTrackingMode(): GeneratedUserTrackingMode {
    return when (this) {
        UserTrackingMode.NO_TRACKING -> GeneratedUserTrackingMode.NO_TRACKING
        UserTrackingMode.ANONYMOUS_TRACKING -> GeneratedUserTrackingMode.ANONYMOUS_TRACKING
    }
}