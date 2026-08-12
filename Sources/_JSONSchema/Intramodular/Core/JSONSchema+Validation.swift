//
// Copyright (c) Vatsal Manot
//

import Foundation
import _JSON

extension JSONSchema {
    public struct ValidationError: Error, CustomStringConvertible, Equatable, Sendable {
        public let path: String
        public let reason: String

        public init(path: String, reason: String) {
            self.path = path
            self.reason = reason
        }

        public var description: String {
            "JSON value at \(path) is invalid: \(reason)"
        }
    }

    /// Validates a JSON instance against the represented Draft 2020-12
    /// vocabulary. `format`, `readOnly`, and `writeOnly` remain annotations.
    /// Local references into this schema's `$defs` are resolved; fetching
    /// external schemas is deliberately outside this API.
    public func validate(_ instance: JSON) throws {
        try validate(instance, root: self, path: "$")
    }

    /// Encodes a value as JSON before validating it against this schema.
    public func validate<Value: Encodable>(_ instance: Value) throws {
        let data = try JSONEncoder().encode(instance)
        try validate(try JSONDecoder().decode(JSON.self, from: data))
    }

    /// Decodes JSON instance bytes before validating them. This deliberately
    /// has a distinct name because `Data` is itself `Encodable`.
    public func validateJSON(_ data: Data, decoder: JSONDecoder = JSONDecoder()) throws {
        try validate(try decoder.decode(JSON.self, from: data))
    }

    private func validate(_ instance: JSON, root: JSONSchema, path: String) throws {
        if booleanValue == false {
            throw ValidationError(path: path, reason: "the Boolean schema is false")
        }
        if booleanValue == true {
            return
        }

        if let ref {
            try root.resolveLocalReference(ref).validate(instance, root: root, path: path)
        }

        try allOf?.forEach { try $0.validate(instance, root: root, path: path) }

        if let anyOf, !anyOf.contains(where: { $0.matches(instance, root: root, path: path) }) {
            throw ValidationError(path: path, reason: "matched no anyOf alternative")
        }

        if let oneOf {
            let count = oneOf.reduce(into: 0) { count, schema in
                if schema.matches(instance, root: root, path: path) {
                    count += 1
                }
            }
            guard count == 1 else {
                throw ValidationError(
                    path: path,
                    reason: "matched \(count) oneOf alternatives instead of exactly one"
                )
            }
        }

        if let not, not.matches(instance, root: root, path: path) {
            throw ValidationError(path: path, reason: "matched a prohibited schema")
        }

        if let condition {
            if condition.matches(instance, root: root, path: path) {
                try then?.validate(instance, root: root, path: path)
            } else {
                try self.else?.validate(instance, root: root, path: path)
            }
        }

        let allowedTypes = types ?? type.map { [$0] }
        if let allowedTypes, !allowedTypes.contains(where: { $0.matches(instance) }) {
            throw ValidationError(
                path: path,
                reason: "expected type \(allowedTypes.map(\.rawValue).joined(separator: " or "))"
            )
        }

        if let values = self.enum, !values.map(\.jsonValue).contains(instance) {
            throw ValidationError(path: path, reason: "is not an allowed enum value")
        }
        if let const, const.value.jsonValue != instance {
            throw ValidationError(path: path, reason: "does not equal the required constant")
        }

        switch instance {
        case .dictionary(let object):
            try validateObject(object, root: root, path: path)
        case .array(let array):
            try validateArray(array, root: root, path: path)
        case .string(let string):
            try validateString(string, path: path)
        case .number(let number):
            try validateNumber(number, path: path)
        case .null, .bool, .date:
            break
        }
    }

    private func validateObject(
        _ object: [String: JSON],
        root: JSONSchema,
        path: String
    ) throws {
        for key in required ?? [] where object[key] == nil {
            throw ValidationError(path: "\(path).\(key)", reason: "is required")
        }
        if let minProperties, object.count < minProperties {
            throw ValidationError(path: path, reason: "has fewer than \(minProperties) properties")
        }
        if let maxProperties, object.count > maxProperties {
            throw ValidationError(path: path, reason: "has more than \(maxProperties) properties")
        }

        for (key, value) in object {
            if let propertyNames {
                try propertyNames.validate(
                    .string(key), root: root, path: "\(path).<property name>")
            }

            var matched = false
            if let schema = properties?[key] {
                matched = true
                try schema.validate(value, root: root, path: "\(path).\(key)")
            }
            for (pattern, schema) in patternProperties ?? [:] {
                if try Self.matches(pattern: pattern, string: key) {
                    matched = true
                    try schema.validate(value, root: root, path: "\(path).\(key)")
                }
            }

            guard !matched, let additionalProperties else {
                continue
            }
            switch additionalProperties {
            case .boolean(true):
                break
            case .boolean(false):
                throw ValidationError(
                    path: "\(path).\(key)", reason: "is not declared by the schema")
            case .schema(let schema):
                try schema.validate(value, root: root, path: "\(path).\(key)")
            }
        }

        for (key, dependencies) in dependentRequired ?? [:] where object[key] != nil {
            for dependency in dependencies where object[dependency] == nil {
                throw ValidationError(
                    path: "\(path).\(dependency)",
                    reason: "is required when \(key) is present"
                )
            }
        }
        for (key, schema) in dependentSchemas ?? [:] where object[key] != nil {
            try schema.validate(.dictionary(object), root: root, path: path)
        }
    }

    private func validateArray(_ array: [JSON], root: JSONSchema, path: String) throws {
        if let minItems, array.count < minItems {
            throw ValidationError(path: path, reason: "has fewer than \(minItems) items")
        }
        if let maxItems, array.count > maxItems {
            throw ValidationError(path: path, reason: "has more than \(maxItems) items")
        }
        if uniqueItems == true, Set(array).count != array.count {
            throw ValidationError(path: path, reason: "contains duplicate items")
        }

        for (index, schema) in (prefixItems ?? []).enumerated() where index < array.count {
            try schema.validate(array[index], root: root, path: "\(path)[\(index)]")
        }
        if let items {
            for index in (prefixItems?.count ?? 0)..<array.count {
                try items.validate(array[index], root: root, path: "\(path)[\(index)]")
            }
        }

        if let contains {
            let count = array.indices.filter {
                contains.matches(array[$0], root: root, path: "\(path)[\($0)]")
            }.count
            let minimum = minContains ?? 1
            if count < minimum {
                throw ValidationError(
                    path: path, reason: "contains fewer than \(minimum) matching items")
            }
            if let maxContains, count > maxContains {
                throw ValidationError(
                    path: path, reason: "contains more than \(maxContains) matching items")
            }
        }
    }

    private func validateString(_ string: String, path: String) throws {
        let length = string.unicodeScalars.count
        if let minLength, length < minLength {
            throw ValidationError(path: path, reason: "is shorter than \(minLength) characters")
        }
        if let maxLength, length > maxLength {
            throw ValidationError(path: path, reason: "is longer than \(maxLength) characters")
        }
        if let pattern, try !Self.matches(pattern: pattern, string: string) {
            throw ValidationError(path: path, reason: "does not match pattern \(pattern)")
        }
    }

    private func validateNumber(_ number: JSONNumber, path: String) throws {
        let value = number.approximateDoubleValue
        if let minimum, value < minimum {
            throw ValidationError(path: path, reason: "is less than \(minimum)")
        }
        if let maximum, value > maximum {
            throw ValidationError(path: path, reason: "is greater than \(maximum)")
        }
        if let exclusiveMinimum, value <= exclusiveMinimum {
            throw ValidationError(path: path, reason: "is not greater than \(exclusiveMinimum)")
        }
        if let exclusiveMaximum, value >= exclusiveMaximum {
            throw ValidationError(path: path, reason: "is not less than \(exclusiveMaximum)")
        }
        if let multipleOf {
            let quotient = value / multipleOf
            guard quotient.isFinite,
                abs(quotient.rounded() - quotient) <= Double.ulpOfOne * max(abs(quotient), 1)
            else {
                throw ValidationError(path: path, reason: "is not a multiple of \(multipleOf)")
            }
        }
    }

    private func matches(_ instance: JSON, root: JSONSchema, path: String) -> Bool {
        do {
            try validate(instance, root: root, path: path)
            return true
        } catch {
            return false
        }
    }

    private func resolveLocalReference(_ reference: String) throws -> JSONSchema {
        let prefix = "#/$defs/"
        guard reference.hasPrefix(prefix) else {
            throw ValidationError(
                path: "$ref", reason: "external reference \(reference) is unsupported")
        }
        let name = reference.dropFirst(prefix.count)
            .replacingOccurrences(of: "~1", with: "/")
            .replacingOccurrences(of: "~0", with: "~")
        guard let definition = definitions?[name] else {
            throw ValidationError(path: "$ref", reason: "cannot resolve \(reference)")
        }
        return definition
    }

    private static func matches(pattern: String, string: String) throws -> Bool {
        let expression = try NSRegularExpression(pattern: pattern)
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        return expression.firstMatch(in: string, range: range) != nil
    }
}

extension JSONSchema.SchemaType {
    fileprivate func matches(_ value: JSON) -> Bool {
        switch (self, value) {
        case (.null, .null), (.boolean, .bool), (.object, .dictionary),
            (.array, .array), (.number, .number), (.string, .string):
            true
        case (.integer, .number(let number)):
            number.integerValue != nil
        default:
            false
        }
    }
}

extension JSONSchema.EnumValue {
    fileprivate var jsonValue: JSON {
        switch self {
        case .null: .null
        case .boolean(let value): .bool(value)
        case .string(let value): .string(value)
        case .integer(let value): .number(.init(value))
        case .number(let value): .number(.init(value))
        case .array(let value): .array(value.map(\.jsonValue))
        case .object(let value): .dictionary(value.mapValues(\.jsonValue))
        }
    }
}

extension JSONSchema.SchemaConstant.Value {
    fileprivate var jsonValue: JSON {
        switch self {
        case .null: .null
        case .boolean(let value): .bool(value)
        case .integer(let value): .number(.init(value))
        case .number(let value): .number(.init(value))
        case .string(let value): .string(value)
        case .array(let value): .array(value.map(\.jsonValue))
        case .object(let value): .dictionary(value.mapValues(\.jsonValue))
        }
    }
}
