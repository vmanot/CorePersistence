//
// Copyright (c) Vatsal Manot
//

import Foundation
import SwiftUI

extension JSONSchema {
    public struct Property: Codable, Hashable, Sendable {
        private enum CodingKeys: String, CodingKey {
            case type
            case description
            case format
            case items
            case requiredProperties
            case pattern
            case const
            case enumValues = "enum"
            case multipleOf, minimum, maximum
            case minItems, maxItems, uniqueItems
        }
        
        public var type: JSONType
        public var description: String?
        public var format: String?
        public var items: Items?
        public var requiredProperties: [String]?
        public var pattern: String?
        public var const: String?
        public var enumValues: [String]?
        public var multipleOf: Int?
        public var minimum: Double?
        public var maximum: Double?
        public var minItems: Int?
        public var maxItems: Int?
        public var uniqueItems: Bool?
        
        public init(
            type: JSONType,
            description: String? = nil,
            format: String? = nil,
            items: Items? = nil,
            requiredProperties: [String]? = nil,
            pattern: String? = nil,
            const: String? = nil,
            enumValues: [String]? = nil,
            multipleOf: Int? = nil,
            minimum: Double? = nil,
            maximum: Double? = nil,
            minItems: Int? = nil,
            maxItems: Int? = nil,
            uniqueItems: Bool? = nil
        ) {
            self.type = type
            self.description = description
            self.format = format
            self.items = items
            self.requiredProperties = requiredProperties
            self.pattern = pattern
            self.const = const
            self.enumValues = enumValues
            self.multipleOf = multipleOf
            self.minimum = minimum
            self.maximum = maximum
            self.minItems = minItems
            self.maxItems = maxItems
            self.uniqueItems = uniqueItems
        }
    }
}

extension JSONSchema {
    public init(from schema: JSONSchema.Property) {
        self.type = schema.type
        self.items = schema.items
        self.requiredProperties = schema.requiredProperties
        self.pattern = schema.pattern
        self.const = schema.const
        self.enumValues = schema.enumValues
        self.multipleOf = schema.multipleOf
        // self.minimum = schema.minimum
        // self.minimum = schema.maximum
    }
}

extension JSONSchema.Property {
    public init(from schema: JSONSchema) {
        self.type = schema.type
        self.items = schema.items
        assert(schema.properties.isNilOrEmpty)
        self.requiredProperties = schema.requiredProperties
        self.pattern = schema.pattern
        self.const = schema.const
        self.enumValues = schema.enumValues
        self.multipleOf = schema.multipleOf
        // self.minimum = schema.minimum
        // self.minimum = schema.maximum
    }
}
