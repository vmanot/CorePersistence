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
        
    public static func array(_ schema: JSONSchema) -> JSONSchema {
        JSONSchema(type: .array, items: schema)
    }
    
    public static func object(
        properties: [String: JSONSchema]
    ) -> JSONSchema {
        JSONSchema(type: .object, properties: properties)
    }
}
