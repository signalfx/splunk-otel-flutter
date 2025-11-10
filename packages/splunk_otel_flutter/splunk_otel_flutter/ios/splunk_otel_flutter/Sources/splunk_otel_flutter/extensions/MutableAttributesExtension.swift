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
import OpenTelemetryApi


extension MutableAttributes {
    func toGeneratedMutableAttributes() -> GeneratedMutableAttributes {
        var generatedMap: [String: Any?] = [:]
        let snapshot = self.getAll()
        
        snapshot.forEach { key, value in
            generatedMap[key] = value.toGeneratedWrapper()
        }
        
        return GeneratedMutableAttributes(attributes: generatedMap)
    }
    
}

extension AttributeArray {
    static func fromIntArray(_ values: [Int64]) -> AttributeArray {
        values.isEmpty ? .empty : AttributeArray(values: values.map { .int(Int($0)) })
    }
    
    static func fromBoolArray(_ values: [Bool]) -> AttributeArray {
        values.isEmpty ? .empty : AttributeArray(values: values.map { .bool($0) })
    }
    
    static func fromStringArray(_ values: [String]) -> AttributeArray {
        values.isEmpty ? .empty : AttributeArray(values: values.map { .string($0) })
    }
    
    static func fromDoubleArray(_ values: [Double]) -> AttributeArray {
        values.isEmpty ? .empty : AttributeArray(values: values.map { .double($0) })
    }
}

extension GeneratedMutableAttributes {
    func toMutableAttributes() -> MutableAttributes {
        let mutableAttributes = MutableAttributes()
        
        self.attributes.forEach { key, generatedValueWrapper in
            switch generatedValueWrapper {
                
                // Scalars
            case let v as GeneratedMutableAttributeInt:
                mutableAttributes[key] = .int(Int(v.value))
                
            case let v as GeneratedMutableAttributeDouble:
                mutableAttributes[key] = .double(v.value)
                
            case let v as GeneratedMutableAttributeString:
                mutableAttributes[key] = .string(v.value)
                
            case let v as GeneratedMutableAttributeBool:
                mutableAttributes[key] = .bool(v.value)
                
            case let v as GeneratedMutableAttributeListInt:
                mutableAttributes[key] = .intArray(v.value.map(Int.init))
                
            case let v as GeneratedMutableAttributeListDouble:
                mutableAttributes[key] = .doubleArray(v.value)
                
            case let v as GeneratedMutableAttributeListString:
                mutableAttributes[key] = .stringArray(v.value)
                
            case let v as GeneratedMutableAttributeListBool:
                mutableAttributes[key] = .boolArray(v.value)
                
            case .none:
                break
                
            default:
                fatalError("Unsupported GeneratedMutableAttribute type for key \(key): \(String(describing: generatedValueWrapper))")
            }
        }
        
        return mutableAttributes
    }
}


extension AttributeValue {
    func toGeneratedWrapper() -> Any? {
          switch self {
          case .int(let v):
              return GeneratedMutableAttributeInt(value: Int64(v))
          case .double(let v):
              return GeneratedMutableAttributeDouble(value: v)
          case .string(let v):
              return GeneratedMutableAttributeString(value: v)
          case .bool(let v):
              return GeneratedMutableAttributeBool(value: v)

          // Unified array case
          case .array(let arr):
              return wrapAttributeArray(arr)

          // Deprecated array cases — forward through the same normalizer
          case .stringArray(let v):
              return wrapAttributeArray(AttributeArray(values: v.map { .string($0) }))
          case .boolArray(let v):
              return wrapAttributeArray(AttributeArray(values: v.map { .bool($0) }))
          case .intArray(let v):
              return wrapAttributeArray(AttributeArray(values: v.map { .int($0) }))
          case .doubleArray(let v):
              return wrapAttributeArray(AttributeArray(values: v.map { .double($0) }))

          case .set:
                    return GeneratedMutableAttributeListString(value: [])
                }
      }
    
    // MARK: AttributeArray handling
    func wrapAttributeArray(_ array: AttributeArray) -> Any? {
        let values = array.values
        guard !values.isEmpty else {
            return nil
        }

        do {
            var out: [String] = []
            out.reserveCapacity(values.count)
            for v in values {
                if case let .string(s) = v { out.append(s) } else { out.removeAll(keepingCapacity: true); break }
            }
            if !out.isEmpty && out.count == values.count {
                return GeneratedMutableAttributeListString(value: out)
            }
        }

        do {
            var out: [Bool] = []
            out.reserveCapacity(values.count)
            for v in values {
                if case let .bool(b) = v { out.append(b) } else { out.removeAll(keepingCapacity: true); break }
            }
            if !out.isEmpty && out.count == values.count {
                return GeneratedMutableAttributeListBool(value: out)
            }
        }

        do {
            var out: [Int64] = []
            out.reserveCapacity(values.count)
            for v in values {
                if case let .int(i) = v { out.append(Int64(i)) } else { out.removeAll(keepingCapacity: true); break }
            }
            if !out.isEmpty && out.count == values.count {
                return GeneratedMutableAttributeListInt(value: out)
            }
        }

        do {
            var out: [Double] = []
            out.reserveCapacity(values.count)
            for v in values {
                if case let .double(d) = v { out.append(d) } else { out.removeAll(keepingCapacity: true); break }
            }
            if !out.isEmpty && out.count == values.count {
                return GeneratedMutableAttributeListDouble(value: out)
            }
        }
        return nil
    }
}

