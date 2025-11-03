package com.splunk.rum.flutter.extensions

import android.graphics.Rect
import com.splunk.rum.flutter.GeneratedRecordingMaskElement
import com.splunk.rum.flutter.GeneratedRecordingMaskList
import com.splunk.rum.flutter.GeneratedRecordingMaskType
import com.splunk.rum.flutter.GeneratedRect
import com.splunk.rum.integration.sessionreplay.api.RecordingMask

fun GeneratedRecordingMaskType.toRecordingMaskType(): RecordingMask.Element.Type {
    return when (this) {
        GeneratedRecordingMaskType.COVERING -> RecordingMask.Element.Type.COVERING
        GeneratedRecordingMaskType.ERASING -> RecordingMask.Element.Type.ERASING
    }
}

fun RecordingMask.Element.Type.toGeneratedRecordingMaskType(): GeneratedRecordingMaskType {
    return when (this) {
        RecordingMask.Element.Type.COVERING -> GeneratedRecordingMaskType.COVERING
        RecordingMask.Element.Type.ERASING -> GeneratedRecordingMaskType.ERASING
    }
}

fun RecordingMask.toGeneratedRecordingMaskList(): GeneratedRecordingMaskList {
    return GeneratedRecordingMaskList(
        this.elements.map {
            it.toGeneratedRecordingMask()
        })
}

fun GeneratedRecordingMaskList.toGeneratedRecordingMaskList(): RecordingMask {
    return RecordingMask(
        this.recordingMaskList?.map {
            it.toRecordingMask()
        } as List<RecordingMask.Element>)
}

fun GeneratedRecordingMaskElement.toRecordingMask(): RecordingMask.Element {
    return RecordingMask.Element(
        this.rect.toRect(),
        this.type.toRecordingMaskType()
    )
}

fun RecordingMask.Element.toGeneratedRecordingMask(): GeneratedRecordingMaskElement {
    return GeneratedRecordingMaskElement(
        rect = this.rect.toGeneratedRect(),
        type = this.type.toGeneratedRecordingMaskType()
    )
}

fun GeneratedRect.toRect(): Rect {
    return Rect(left.toInt(), top.toInt(), (left + width).toInt(), (top + height).toInt())
}

fun Rect.toGeneratedRect(): GeneratedRect {
    return GeneratedRect(left.toDouble(), top.toDouble(), width().toDouble(), height().toDouble())
}