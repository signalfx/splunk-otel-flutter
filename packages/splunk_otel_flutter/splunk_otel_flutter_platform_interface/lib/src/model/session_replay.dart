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

/// Status of session replay recording.
enum SessionReplayStatus {
  /// Session replay is actively recording.
  isRecording,

  /// Recording has not been started.
  notStarted,

  /// Recording was stopped.
  stopped,

  /// The device's Android SDK is below the supported minimum version.
  belowMinSdkVersion,

  /// The device's storage is too low to start recording.
  storageLimitReached,

  /// Recording could not start due to an internal error.
  ///
  /// This typically occurs when the internal database cannot be opened
  /// or another internal error occurred.
  internalError,

  /// Recording is disabled because the session was not sampled.
  disabledBySampling,
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
      case SessionReplayStatus.disabledBySampling:
        return GeneratedSessionReplayStatus.disabledBySampling;
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
      case GeneratedSessionReplayStatus.disabledBySampling:
        return SessionReplayStatus.disabledBySampling;
    }
  }
}

/// A recording mask for session replay.
///
/// Masks are used to hide or obscure sensitive content during session replay.
class RecordingMask {
  /// The list of mask elements.
  final List<MaskElement> elements;

  /// Creates a recording mask.
  RecordingMask({required this.elements});
}

/// A single mask element that defines an area to mask in session replay.
class MaskElement {
  /// The rectangular area to mask.
  final Rect rect;

  /// The type of masking to apply.
  final MaskType type;

  /// Creates a mask element.
  MaskElement({required this.rect, required this.type});
}

/// Type of recording mask to apply.
enum MaskType {
  /// Erase the content in the masked area.
  erasing,

  /// Cover the content with a solid overlay.
  covering,
}

extension RectExtension on Rect {
  GeneratedRect toGeneratedRect() {
    return GeneratedRect(left: left, top: top, width: width, height: height);
  }
}

extension GeneratedRectExtension on GeneratedRect {
  Rect toRect() {
    return Rect.fromLTWH(left, top, width, height);
  }
}

extension MaskTypeExtension on MaskType {
  GeneratedRecordingMaskType toGeneratedRecordingMaskType() {
    switch (this) {
      case MaskType.erasing:
        return GeneratedRecordingMaskType.erasing;
      case MaskType.covering:
        return GeneratedRecordingMaskType.covering;
    }
  }
}

extension GeneratedRecordingMaskTypeExtension on GeneratedRecordingMaskType {
  MaskType toMaskType() {
    switch (this) {
      case GeneratedRecordingMaskType.erasing:
        return MaskType.erasing;
      case GeneratedRecordingMaskType.covering:
        return MaskType.covering;
    }
  }
}

extension MaskElementExtension on MaskElement {
  GeneratedRecordingMaskElement toGeneratedRecordingMaskElement() {
    return GeneratedRecordingMaskElement(
      rect: rect.toGeneratedRect(),
      type: type.toGeneratedRecordingMaskType(),
    );
  }
}

extension GeneratedRecordingMaskElementExtension
    on GeneratedRecordingMaskElement {
  MaskElement toMaskElement() {
    return MaskElement(rect: rect.toRect(), type: type.toMaskType());
  }
}

extension RecordingMaskExtension on RecordingMask {
  GeneratedRecordingMaskList toGeneratedRecordingMaskList() {
    return GeneratedRecordingMaskList(
      recordingMaskList: elements
          .map((element) => element.toGeneratedRecordingMaskElement())
          .toList(),
    );
  }
}

extension GeneratedRecordingMaskListExtension on GeneratedRecordingMaskList {
  RecordingMask toRecordingMask() {
    return RecordingMask(
      elements:
          recordingMaskList
              ?.map((element) => element.toMaskElement())
              .toList() ??
          [],
    );
  }
}
