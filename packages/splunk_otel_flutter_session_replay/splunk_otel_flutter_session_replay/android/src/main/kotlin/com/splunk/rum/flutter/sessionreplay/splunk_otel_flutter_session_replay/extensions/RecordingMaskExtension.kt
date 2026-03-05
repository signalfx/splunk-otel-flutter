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

package com.splunk.rum.flutter.sessionreplay.splunk_otel_flutter_session_replay.extensions

import android.graphics.Rect
import com.splunk.rum.flutter.sessionreplay.GeneratedRecordingMaskElement
import com.splunk.rum.flutter.sessionreplay.GeneratedRecordingMaskList
import com.splunk.rum.flutter.sessionreplay.GeneratedRecordingMaskType
import com.splunk.rum.flutter.sessionreplay.GeneratedRect
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
        this.elements.map { it.toGeneratedRecordingMask() }
    )
}

fun GeneratedRecordingMaskList.toRecordingMaskList(): RecordingMask {
    return RecordingMask(
        this.recordingMaskList?.map { it.toRecordingMask() } as List<RecordingMask.Element>
    )
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
