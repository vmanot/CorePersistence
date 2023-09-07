//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension JSONSchema {
    public struct Items: Codable, Hashable, Sendable {
        private enum CodingKeys: String, CodingKey {
            case type, properties, pattern, const
            case enumValues = "enum"
            case multipleOf
            case minItems
            case maxItems
            case uniqueItems
        }
        
        public var type: JSONType
        public var properties: [String: Property]?
        public var pattern: String?
        public var const: String?
        public var enumValues: [String]?
        public var multipleOf: Int?
        public var minItems: Int?
        public var maxItems: Int?
        public var uniqueItems: Bool?
        
        public init(
            type: JSONType,
            properties: [String: Property]? = nil,
            pattern: String? = nil,
            const: String? = nil,
            enumValues: [String]? = nil,
            multipleOf: Int? = nil,
            minItems: Int? = nil,
            maxItems: Int? = nil,
            uniqueItems: Bool? = nil
        ) {
            self.type = type
            self.properties = properties
            self.pattern = pattern
            self.const = const
            self.enumValues = enumValues
            self.multipleOf = multipleOf
            self.minItems = minItems
            self.maxItems = maxItems
            self.uniqueItems = uniqueItems
        }
        
        public init(_ schema: JSONSchema) {
            self.type = schema.type
            self.properties = schema.properties
            self.pattern = schema.pattern
            self.const = schema.const
            self.enumValues = schema.enumValues
            self.multipleOf = schema.multipleOf
        }
    }
}
