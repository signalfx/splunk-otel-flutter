import Foundation
import SplunkAgent
import OpenTelemetryApi


func mutableAttributes(from json: [String: Any]) -> MutableAttributes {
    let attributes = MutableAttributes()
    
    for (key, rawValue) in json {
        if let attrValue = convertToAttributeValue(rawValue) {
            attributes.setValue(attrValue, for: key)
        }
    }
    return attributes
}

private func convertToAttributeValue(_ raw: Any, inArray: Bool = false) -> AttributeValue? {
    switch raw {
    case let str as String:
        return .string(str)

    case let num as NSNumber:
        let objCType = String(cString: num.objCType)
        if objCType == "c" {
            return .bool(num.boolValue)
        }
        if inArray {
            // Preserve all numeric values as strings inside arrays
            return .string(num.stringValue)
        } else {
            if CFNumberGetType(num) == .sInt64Type ||
               CFNumberGetType(num) == .intType ||
               CFNumberGetType(num) == .longType {
                return .int(num.intValue)
            }
            return .double(num.doubleValue)
        }

    case let array as [Any]:
        let convertedValues = array.compactMap { convertToAttributeValue($0, inArray: true) }
        return .array(AttributeArray(values: convertedValues))

    case let dict as [String: Any]:
        let convertedDict = dict.compactMapValues { convertToAttributeValue($0) }
        return .set(AttributeSet(labels: convertedDict))

    default:
        return nil
    }
}
