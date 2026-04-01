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
  Future<void> sessionReplayStart() async {
    await _api.sessionReplayStart();
  }

  @override
  Future<void> sessionReplayStop() async {
    await _api.sessionReplayStop();
  }

  @override
  Future<SessionReplayStatus> sessionReplayStateGetStatus() async {
    final generatedStatus = await _api.sessionReplayStateGetStatus();
    return generatedStatus._toSessionReplayStatus();
  }

  @override
  Future<RenderingMode> sessionReplayStateGetRenderingMode() async {
    final generatedMode = await _api.sessionReplayStateGetRenderingMode();
    return generatedMode._toRenderingMode();
  }

  @override
  Future<RenderingMode?> sessionReplayPreferencesGetRenderingMode() async {
    final generatedMode =
        await _api.sessionReplayPreferencesGetRenderingMode();
    return generatedMode?._toRenderingMode();
  }

  @override
  Future<void> sessionReplayPreferencesSetRenderingMode(
          {required RenderingMode? renderingMode}) async =>
      await _api.sessionReplayPreferencesSetRenderingMode(
          renderingMode: renderingMode?._toGenerated());

  @override
  Future<RecordingMaskList?> sessionReplayGetRecordingMask() async {
    final generatedMask = await _api.sessionReplayGetRecordingMask();
    return generatedMask?._toRecordingMaskList();
  }

  @override
  Future<void> sessionReplaySetRecordingMask(
          {required RecordingMaskList? recordingMask}) async =>
      await _api.sessionReplaySetRecordingMask(
        recordingMask: recordingMask?._toGenerated(),
      );
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

extension on GeneratedRenderingMode {
  RenderingMode _toRenderingMode() {
    switch (this) {
      case GeneratedRenderingMode.native:
        return RenderingMode.native;
      case GeneratedRenderingMode.wireframeOnly:
        return RenderingMode.wireframeOnly;
    }
  }
}

extension on RenderingMode {
  GeneratedRenderingMode _toGenerated() {
    switch (this) {
      case RenderingMode.native:
        return GeneratedRenderingMode.native;
      case RenderingMode.wireframeOnly:
        return GeneratedRenderingMode.wireframeOnly;
    }
  }
}

extension on GeneratedRecordingMaskList {
  RecordingMaskList _toRecordingMaskList() {
    return RecordingMaskList(
        elements: recordingMaskList
                ?.map((e) => RecordingMaskElement(
                      rect: Rect.fromLTWH(
                          e.rect.left, e.rect.top, e.rect.width, e.rect.height),
                      type: e.type == GeneratedRecordingMaskType.erasing
                          ? RecordingMaskType.erasing
                          : RecordingMaskType.covering,
                    ))
                .toList() ??
            []);
  }
}

extension on RecordingMaskList {
  GeneratedRecordingMaskList _toGenerated() {
    return GeneratedRecordingMaskList(
        recordingMaskList: elements
            .map((e) => GeneratedRecordingMaskElement(
                  rect: GeneratedRect(
                    left: e.rect.left,
                    top: e.rect.top,
                    width: e.rect.width,
                    height: e.rect.height,
                  ),
                  type: e.type == RecordingMaskType.erasing
                      ? GeneratedRecordingMaskType.erasing
                      : GeneratedRecordingMaskType.covering,
                ))
            .toList());
  }
}
