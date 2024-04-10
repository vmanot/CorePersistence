//
// Copyright (c) Vatsal Manot
//

import Swift

extension JSONSchema {
    public static func array(_ schema: JSONSchema) -> JSONSchema {
        JSONSchema(type: .array, items: schema)
    }
}
