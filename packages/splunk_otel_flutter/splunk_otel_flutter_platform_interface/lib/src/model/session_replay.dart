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

import 'dart:ui';

import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

enum SessionReplayStatus {
  isRecording,

  /// Recording have not been started.
  notStarted,

  /// Recording was stopped.
  stopped,

  /// The device's Android sdk is below supported minimum.
  belowMinSdkVersion,

  /// The device's storage is too low to start recording.
  storageLimitReached,

  ///  It was impossible to start the recording because the internal
  ///  database could not be open, or another internal error occurred.
  internalError,
}

extension SessionReplayStatusExtension on SessionReplayStatus {
  GeneratedSessionReplayStatus toGeneratedSessionReplayStatus() {
    switch (this) {
      case SessionReplayStatus.isRecording:
        return GeneratedSessionReplayStatus.isRecording;
      case SessionReplayStatus.notStarted:
        return GeneratedSessionReplayStatus.notStarted;
      case SessionReplayStatus.stopped:
        return GeneratedSessionReplayStatus.stopped;
      case SessionReplayStatus.belowMinSdkVersion:
        return GeneratedSessionReplayStatus.belowMinSdkVersion;
      case SessionReplayStatus.storageLimitReached:
        return GeneratedSessionReplayStatus.storageLimitReached;
      case SessionReplayStatus.internalError:
        return GeneratedSessionReplayStatus.internalError;
    }
  }
}

extension GeneratedSessionReplayStatusExtension
    on GeneratedSessionReplayStatus {
  SessionReplayStatus toSessionReplayStatus() {
    switch (this) {
      case GeneratedSessionReplayStatus.isRecording:
        return SessionReplayStatus.isRecording;
      case GeneratedSessionReplayStatus.notStarted:
        return SessionReplayStatus.notStarted;
      case GeneratedSessionReplayStatus.stopped:
        return SessionReplayStatus.stopped;
      case GeneratedSessionReplayStatus.belowMinSdkVersion:
        return SessionReplayStatus.belowMinSdkVersion;
      case GeneratedSessionReplayStatus.storageLimitReached:
        return SessionReplayStatus.storageLimitReached;
      case GeneratedSessionReplayStatus.internalError:
        return SessionReplayStatus.internalError;
    }
  }
}

enum RenderingMode {
  native,
  wireframeOnly,
}

extension RenderingModeExtension on RenderingMode {
  GeneratedRenderingMode toGeneratedRenderingMode() {
    switch (this) {
      case RenderingMode.native:
        return GeneratedRenderingMode.native;
      case RenderingMode.wireframeOnly:
        return GeneratedRenderingMode.wireframeOnly;
    }
  }
}

extension GeneratedRenderingModeExtension on GeneratedRenderingMode {
  RenderingMode toRenderingMode() {
    switch (this) {
      case GeneratedRenderingMode.native:
        return RenderingMode.native;
      case GeneratedRenderingMode.wireframeOnly:
        return RenderingMode.wireframeOnly;
    }
  }
}

class RecordingMaskList {
  final List<RecordingMaskElement> elements;

  RecordingMaskList({required this.elements});
}

class RecordingMaskElement {
  final Rect rect;
  final RecordingMaskType type;

  RecordingMaskElement({required this.rect, required this.type});
}

enum RecordingMaskType {
  erasing,
  covering,
}

extension RectExtension on Rect {
  GeneratedRect toGeneratedRect() {
    return GeneratedRect(
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }
}

extension GeneratedRectExtension on GeneratedRect {
  Rect toRect() {
    return Rect.fromLTWH(left, top, width, height);
  }
}

extension RecordingMaskTypeExtension on RecordingMaskType {
  GeneratedRecordingMaskType toGeneratedRecordingMaskType() {
    switch (this) {
      case RecordingMaskType.erasing:
        return GeneratedRecordingMaskType.erasing;
      case RecordingMaskType.covering:
        return GeneratedRecordingMaskType.covering;
    }
  }
}

extension GeneratedRecordingMaskTypeExtension on GeneratedRecordingMaskType {
  RecordingMaskType toRecordingMaskType() {
    switch (this) {
      case GeneratedRecordingMaskType.erasing:
        return RecordingMaskType.erasing;
      case GeneratedRecordingMaskType.covering:
        return RecordingMaskType.covering;
    }
  }
}

extension RecordingMaskExtension on RecordingMaskElement {
  GeneratedRecordingMaskElement toGeneratedRecordingMaskElement() {
    return GeneratedRecordingMaskElement(
      rect: rect.toGeneratedRect(),
      type: type.toGeneratedRecordingMaskType(),
    );
  }
}

extension GeneratedRecordingMaskExtension on GeneratedRecordingMaskElement {
  RecordingMaskElement toRecordingMask() {
    return RecordingMaskElement(
      rect: rect.toRect(),
      type: type.toRecordingMaskType(),
    );
  }
}

extension RecordingMaskListExtension on RecordingMaskList {
  GeneratedRecordingMaskList toGeneratedRecordingMaskList() {
    return GeneratedRecordingMaskList(
        recordingMaskList: elements
            .map((element) => element.toGeneratedRecordingMaskElement())
            .toList());
  }
}

extension GeneratedRecordingMaskListExtension on GeneratedRecordingMaskList {
  RecordingMaskList toRecordingMaskList() {
    return RecordingMaskList(
        elements: recordingMaskList
                ?.map((element) => element.toRecordingMask())
                .toList() ??
            []);
  }
}
