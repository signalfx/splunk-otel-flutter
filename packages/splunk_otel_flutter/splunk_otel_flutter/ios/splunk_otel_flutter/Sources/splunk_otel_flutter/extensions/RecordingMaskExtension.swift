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

import Foundation
import UIKit
import SplunkAgent
import OpenTelemetryApi

extension GeneratedRecordingMaskType {
    func toRecordingMaskType() -> MaskElement.MaskType {
        switch self {
        case .covering: return .erasing
        case .erasing: return .erasing
        }
    }
}

extension MaskElement.MaskType{
    func toGeneratedRecordingMaskType() -> GeneratedRecordingMaskType {
        switch self {
        case .covering: return .covering
        case .erasing: return .erasing
        @unknown default: return .covering
        }
    }
}

extension GeneratedRecordingMaskElement {
    func toRecordingMaskElement() -> MaskElement {
        MaskElement(rect: self.rect.toRect(), type: self.type.toRecordingMaskType())
    }
}

extension MaskElement {
    func toGeneratedRecordingMask() -> GeneratedRecordingMaskElement {
        GeneratedRecordingMaskElement(rect: self.rect.toGeneratedRect(), type: self.type.toGeneratedRecordingMaskType())
    }
}

extension GeneratedRecordingMaskList {
    func toRecordingMask() -> RecordingMask {
        let elements = self.recordingMaskList?.map { $0.toRecordingMaskElement() } ?? []
        return RecordingMask(elements: elements)
    }
}

extension RecordingMask {
    func toGeneratedRecordingMaskList() -> GeneratedRecordingMaskList {
        let elements = self.elements.map { $0.toGeneratedRecordingMask() }
        return GeneratedRecordingMaskList(recordingMaskList: elements)
    }
}

extension GeneratedRect {
    func toRect() -> CGRect {
        CGRect(x: self.left, y: self.top, width: self.width, height: self.height)
    }
}

extension CGRect {
    func toGeneratedRect() -> GeneratedRect {
        GeneratedRect(left: Double(self.origin.x), top: Double(self.origin.y), width: Double(self.size.width), height: Double(self.size.height))
    }
}
