import CoreFoundation
import Foundation

/// Encodes the integer-valued JSON subset used by durable manifests according
/// to RFC 8785's property ordering and string representation rules.
///
/// Floating-point values are deliberately rejected. Correct ECMAScript number
/// serialization is part of RFC 8785; silently inheriting Foundation's current
/// formatting would make a persistent digest depend on an implementation
/// detail. Schemas using this encoder represent exact values with integers or
/// strings.
public struct CanonicalJSONEncoder: Sendable {
    public enum Error: LocalizedError {
        case nonIntegralNumber(String)
        case unsupportedValue(Any.Type)

        public var errorDescription: String? {
            switch self {
            case .nonIntegralNumber(let value):
                "Canonical JSON encoding requires an integer-valued schema; received \(value)."
            case .unsupportedValue(let type):
                "Canonical JSON cannot encode Foundation value of type \(type)."
            }
        }
    }

    public init() {}

    public func encode(_ value: some Encodable) throws -> Data {
        let encoded: Data = try JSONEncoder().encode(value)
        let object: Any = try JSONSerialization.jsonObject(
            with: encoded,
            options: [.fragmentsAllowed]
        )
        var result = Data()
        try append(object, to: &result)
        return result
    }

    private func append(_ value: Any, to result: inout Data) throws {
        switch value {
        case is NSNull:
            result.append(contentsOf: "null".utf8)
        case let value as NSNumber where CFGetTypeID(value) == CFBooleanGetTypeID():
            result.append(contentsOf: (value.boolValue ? "true" : "false").utf8)
        case let value as NSNumber:
            let representation: String = value.stringValue
            guard Self.isInteger(representation) else {
                throw Error.nonIntegralNumber(representation)
            }
            result.append(contentsOf: representation.utf8)
        case let value as String:
            Self.appendString(value, to: &result)
        case let values as [Any]:
            result.append(0x5B)
            for (index, value) in values.enumerated() {
                if index > 0 {
                    result.append(0x2C)
                }
                try append(value, to: &result)
            }
            result.append(0x5D)
        case let values as [String: Any]:
            result.append(0x7B)
            let keys: [String] = values.keys.sorted(by: Self.utf16Precedes)
            for (index, key) in keys.enumerated() {
                if index > 0 {
                    result.append(0x2C)
                }
                Self.appendString(key, to: &result)
                result.append(0x3A)
                try append(values[key]!, to: &result)
            }
            result.append(0x7D)
        default:
            throw Error.unsupportedValue(Swift.type(of: value))
        }
    }

    private static func isInteger(_ value: String) -> Bool {
        let digits: Substring = value.hasPrefix("-") ? value.dropFirst() : value[...]
        guard !digits.isEmpty, digits.allSatisfy(\.isNumber) else {
            return false
        }
        return digits == "0" || digits.first != "0"
    }

    private static func utf16Precedes(_ lhs: String, _ rhs: String) -> Bool {
        lhs.utf16.lexicographicallyPrecedes(rhs.utf16)
    }

    private static func appendString(_ value: String, to result: inout Data) {
        result.append(0x22)
        for scalar: Unicode.Scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x08:
                result.append(contentsOf: "\\b".utf8)
            case 0x09:
                result.append(contentsOf: "\\t".utf8)
            case 0x0A:
                result.append(contentsOf: "\\n".utf8)
            case 0x0C:
                result.append(contentsOf: "\\f".utf8)
            case 0x0D:
                result.append(contentsOf: "\\r".utf8)
            case 0x22:
                result.append(contentsOf: "\\\"".utf8)
            case 0x5C:
                result.append(contentsOf: "\\\\".utf8)
            case 0x00...0x1F:
                result.append(
                    contentsOf: String(format: "\\u%04x", scalar.value).utf8
                )
            default:
                result.append(contentsOf: String(scalar).utf8)
            }
        }
        result.append(0x22)
    }
}
