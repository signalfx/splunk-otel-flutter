package com.splunk.rum.flutter.extensions

import com.splunk.rum.flutter.GeneratedRenderingMode
import com.splunk.rum.integration.sessionreplay.api.RenderingMode

fun GeneratedRenderingMode.toRenderingMode(): RenderingMode {
    return when (this) {
        GeneratedRenderingMode.NATIVE -> RenderingMode.NATIVE
        GeneratedRenderingMode.WIREFRAME_ONLY -> RenderingMode.WIREFRAME_ONLY
    }
}

fun RenderingMode.toGeneratedRenderingMode(): GeneratedRenderingMode {
    return when (this) {
        RenderingMode.NATIVE -> GeneratedRenderingMode.NATIVE
        RenderingMode.WIREFRAME_ONLY -> GeneratedRenderingMode.WIREFRAME_ONLY
    }
}