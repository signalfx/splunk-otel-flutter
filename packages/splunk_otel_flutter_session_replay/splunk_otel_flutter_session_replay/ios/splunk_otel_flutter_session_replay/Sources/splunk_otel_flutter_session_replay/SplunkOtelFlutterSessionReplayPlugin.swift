/*
Copyright 2026 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import Flutter
import UIKit
import SplunkAgent

public class SplunkOtelFlutterSessionReplayPlugin: NSObject, FlutterPlugin, SplunkOtelFlutterSessionReplayHostApi {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SplunkOtelFlutterSessionReplayPlugin()
        SplunkOtelFlutterSessionReplayHostApiSetup.setUp(
            binaryMessenger: registrar.messenger(),
            api: instance
        )
    }

    func sessionReplayStart(completion: @escaping (Result<Void, Error>) -> Void) {
        SplunkRum.shared.sessionReplay.start()

        completion(.success(()))
    }

    func sessionReplayStop(completion: @escaping (Result<Void, Error>) -> Void) {
        SplunkRum.shared.sessionReplay.stop()

        completion(.success(()))
    }

    func sessionReplayStateGetStatus(completion: @escaping (Result<GeneratedSessionReplayStatus, Error>) -> Void) {
        let status = SplunkRum.shared.sessionReplay.state.status

        completion(.success(status.toGeneratedSessionReplayStatus()))
    }

    func sessionReplayGetRecordingMask(completion: @escaping (Result<GeneratedRecordingMaskList?, Error>) -> Void) {
        let recordingMask = SplunkRum.shared.sessionReplay.recordingMask

        completion(.success(recordingMask?.toGeneratedRecordingMaskList()))
    }

    func sessionReplaySetRecordingMask(recordingMask: GeneratedRecordingMaskList?, completion: @escaping (Result<Void, Error>) -> Void) {
        SplunkRum.shared.sessionReplay.recordingMask = recordingMask?.toRecordingMask()

        completion(.success(()))
    }
}
