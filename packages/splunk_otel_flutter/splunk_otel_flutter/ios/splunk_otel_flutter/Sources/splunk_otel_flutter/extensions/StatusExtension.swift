//
/*
Copyright 2025 Splunk Inc.

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

import SplunkAgent

enum StatusConversionError: Error {
    case invalidStatus(String)
}

extension GeneratedStatus {
    func toAgentApiStatus() throws -> Status {
        switch self {
        case .running:
            return .running
        case .notInstalled:
            return .notRunning(.notInstalled)
        case .sampledOut:
            return .notRunning(.sampledOut)
        case .unsupportedOsVersion:
            return .notRunning(.unsupportedPlatform)
        case .subprocess:
            throw StatusConversionError.invalidStatus("invalid status subprocess")
        case .unsupportedPlatform:
            throw StatusConversionError.invalidStatus("invalid status unsupportedPlatform")
        }
    }
}

extension Status {
    func toGeneratedStatus() -> GeneratedStatus {
        switch self {
        case .running: return .running
        case .notRunning(.notInstalled): return .notInstalled
        case .notRunning(.sampledOut): return .sampledOut
        case .notRunning(.unsupportedPlatform): return .unsupportedPlatform
        default: return .unsupportedOsVersion
        }
    }
}
