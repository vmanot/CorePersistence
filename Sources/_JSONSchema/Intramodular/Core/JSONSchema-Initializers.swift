//
// Copyright (c) Vatsal Manot
//

import Swift

extension JSONSchema {
    public static var integer: JSONSchema {
        JSONSchema(type: .integer)
    }
    
    public static var number: JSONSchema {
        JSONSchema(type: .number)
    }

    public static var string: JSONSchema {
        JSONSchema(type: .string)
    }
        
    public static func array(
        _ schema: JSONSchema
    ) -> JSONSchema {
        JSONSchema(type: .array, items: schema)
    }
    
    public static func array(
        _ schema: () throws -> JSONSchema
    ) rethrows -> JSONSchema {
        JSONSchema(type: .array, items: try schema())
    }
    
    public static func object(
        properties: [String: JSONSchema]
    ) -> JSONSchema {
        JSONSchema(type: .object, properties: properties)
    }
}

extension JSONSchema {
    public init(
        type: SchemaType?,
        description: String? = nil,
        properties: [String: JSONSchema]? = nil,
        required: [String]? = nil,
        additionalProperties: JSONSchema.AdditionalProperties? = nil,
        items: JSONSchema? = nil
    ) {
        self.id = nil
        self.title = nil
        self.description = description
        self.properties = properties
        self.additionalProperties = additionalProperties
        self.required = required
        self.type = type
        self.enum = nil
        self.const = nil
        self.items = items
        self.readOnly = nil
        self.ref = nil
        self.allOf = nil
        self.anyOf = nil
        self.oneOf = nil
    }
    
    public init(
        type: SchemaType?,
        description: String? = nil,
        properties: [String: JSONSchema]? = nil,
        required: Bool,
        additionalProperties: JSONSchema? = nil,
        items: JSONSchema? = nil
    ) {
        self.id = nil
        self.title = nil
        self.description = description
        self.properties = properties
        self.additionalProperties = additionalProperties.map({ JSONSchema.AdditionalProperties.schema($0) })
        self.required = required ? (properties?.keys).map({ Array($0) }) : nil
        self.type = type
        self.enum = nil
        self.const = nil
        self.items = items
        self.readOnly = nil
        self.ref = nil
        self.allOf = nil
        self.anyOf = nil
        self.oneOf = nil
    }
}
