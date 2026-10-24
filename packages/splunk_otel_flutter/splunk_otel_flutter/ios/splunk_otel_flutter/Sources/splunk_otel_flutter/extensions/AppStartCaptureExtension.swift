//
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

import Foundation
import SplunkAgent
#if canImport(splunk_otel_flutter_app_start)
import splunk_otel_flutter_app_start
#endif

extension AppStartCaptureSnapshot {
    func toAppStartLifecycleSnapshot() -> AppStartLifecycleSnapshot {
        AppStartLifecycleSnapshot(
            launchOrigin: launchOrigin.toAppStartLaunchOrigin(),
            didFinishLaunching: didFinishLaunching,
            willEnterForeground: willEnterForeground,
            didBecomeActive: didBecomeActive
        )
    }
}

extension AppStartCaptureLaunchOrigin {
    func toAppStartLaunchOrigin() -> AppStartLaunchOrigin {
        switch self {
        case .foreground:
            return .foreground

        case .background:
            return .background

        case .foregroundResumed:
            return .foregroundResumed

        case .unknown:
            return .unknown

        @unknown default:
            return .unknown
        }
    }
}
