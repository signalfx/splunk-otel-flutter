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

import 'dart:io';
import 'dart:ui';

import 'package:splunk_otel_flutter_platform_interface/splunk_otel_flutter_platform_interface.dart';
import 'package:splunk_otel_flutter_session_replay_platform_interface/platform_interface/splunk_otel_flutter_session_replay_platform_interface.dart';
import 'package:splunk_otel_flutter_session_replay_platform_interface/src/pigeon/messages.pigeon.dart';

class SplunkOtelFlutterSessionReplayPlatformImplementation
    extends SplunkOtelFlutterSessionReplayPlatformInterface {
  SplunkOtelFlutterSessionReplayPlatformImplementation._internal();

  static final SplunkOtelFlutterSessionReplayPlatformImplementation _instance =
      SplunkOtelFlutterSessionReplayPlatformImplementation._internal();

  static SplunkOtelFlutterSessionReplayPlatformImplementation get instance =>
      _instance;

  final _api = SplunkOtelFlutterSessionReplayHostApi();

  @override
  Future<void> start() async {
    await _api.sessionReplayStart();
  }

  @override
  Future<void> stop() async {
    await _api.sessionReplayStop();
  }

  @override
  Future<SessionReplayStatus> getStatus() async {
    final generatedStatus = await _api.sessionReplayStateGetStatus();

    return generatedStatus._toSessionReplayStatus();
  }

  @override
  Future<RecordingMask?> getRecordingMask() async {
    final generatedMask = await _api.sessionReplayGetRecordingMask();

    return generatedMask?._toRecordingMask();
  }

  @override
  Future<void> setRecordingMask({required RecordingMask? mask}) async =>
      await _api.sessionReplaySetRecordingMask(
        recordingMask: mask?._toGenerated(),
      );
}

// Android's android.graphics.Rect consumes physical pixels whereas Flutter
// layouts use logical pixels. iOS CGRect uses points that match logical pixels.
double get _nativeCoordinateScale {
  if (!Platform.isAndroid) {
    return 1.0;
  }

  return PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0;
}

// Private extensions to convert between Pigeon-generated types and domain models.
// These are local to this file because the generated types come from this package's
// own Pigeon output, while the domain types come from splunk_otel_flutter_platform_interface.

extension on GeneratedSessionReplayStatus {
  SessionReplayStatus _toSessionReplayStatus() {
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

extension on GeneratedRecordingMaskList {
  RecordingMask _toRecordingMask() {
    final scale = _nativeCoordinateScale;

    return RecordingMask(
        elements: recordingMaskList
                ?.map((e) => MaskElement(
                      rect: Rect.fromLTWH(
                        e.rect.left / scale,
                        e.rect.top / scale,
                        e.rect.width / scale,
                        e.rect.height / scale,
                      ),
                      type: e.type == GeneratedRecordingMaskType.erasing
                          ? MaskType.erasing
                          : MaskType.covering,
                    ))
                .toList() ??
            []);
  }
}

extension on RecordingMask {
  GeneratedRecordingMaskList _toGenerated() {
    final scale = _nativeCoordinateScale;

    return GeneratedRecordingMaskList(
        recordingMaskList: elements
            .map((e) => GeneratedRecordingMaskElement(
                  rect: GeneratedRect(
                    left: e.rect.left * scale,
                    top: e.rect.top * scale,
                    width: e.rect.width * scale,
                    height: e.rect.height * scale,
                  ),
                  type: e.type == MaskType.erasing
                      ? GeneratedRecordingMaskType.erasing
                      : GeneratedRecordingMaskType.covering,
                ))
            .toList());
  }
}
