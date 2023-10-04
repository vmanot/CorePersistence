//
// Copyright (c) Vatsal Manot
//

import Swift

/// See the [guide](/docs/guides/gpt/function-calling) for examples, and the [JSON Schema reference](https://json-schema.org/understanding-json-schema/) for documentation about the format.
public struct JSONSchema: Codable, Hashable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case type
        case properties
        case requiredProperties = "required"
        case pattern
        case const
        case enumValues = "enum"
        case multipleOf, minimum, maximum
    }
    
    public var type: JSONType
    public var properties: [String: Property]?
    public var requiredProperties: [String]?
    public var pattern: String?
    public var const: String?
    public var enumValues: [String]?
    public var multipleOf: Int?
    public var minimum: Int?
    public var maximum: Int?
        
    public enum JSONType: String, Codable, Hashable, Sendable {
        case integer = "integer"
        case string = "string"
        case boolean = "boolean"
        case array = "array"
        case object = "object"
        case number = "number"
        case `null` = "null"
    }
        
    public init(
        type: JSONType,
        properties: [String: Property]? = nil,
        requiredProperties: [String]? = nil,
        pattern: String? = nil,
        const: String? = nil,
        enumValues: [String]? = nil,
        multipleOf: Int? = nil,
        minimum: Int? = nil,
        maximum: Int? = nil
    ) {
        self.type = type
        self.properties = properties
        self.requiredProperties = requiredProperties
        self.pattern = pattern
        self.const = const
        self.enumValues = enumValues
        self.multipleOf = multipleOf
        self.minimum = minimum
        self.maximum = maximum
    }
}
