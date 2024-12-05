//
// Copyright (c) Vatsal Manot
//

import Swallow

extension JSONSchema: CustomStringConvertible {
    @_implements(CustomStringConvertible, description)
    public var _CustomStringConvertible_description: String {
        var components: [String] = []
        
        if let type = type {
            components.append("type: \(type.rawValue)")
        }
        
        if let title = title {
            components.append("title: \"\(title)\"")
        }
        
        if let description = description {
            components.append("description: \"\(description)\"")
        }
        
        if let properties = properties {
            let propertiesDesc = properties.map { key, value in
                "\(key): \(value)"
            }.joined(separator: ", ")
            components.append("properties: {\(propertiesDesc)}")
        }
        
        if let required = required {
            components.append("required: [\(required.joined(separator: ", "))]")
        }
        
        if let additionalProperties = additionalProperties {
            components.append("additionalProperties: \(additionalProperties)")
        }
        
        if let items = items {
            components.append("items: \(items)")
        }
        
        if let enumValues = self.enum {
            let enumDesc = enumValues.map { "\($0)" }.joined(separator: ", ")
            components.append("enum: [\(enumDesc)]")
        }
        
        if let const = const {
            components.append("const: \(const)")
        }
        
        if let readOnly = readOnly {
            components.append("readOnly: \(readOnly)")
        }
        
        if let ref = ref {
            components.append("$ref: \"\(ref)\"")
        }
        
        if let allOf = allOf {
            components.append("allOf: \(allOf)")
        }
        
        if let anyOf = anyOf {
            components.append("anyOf: \(anyOf)")
        }
        
        if let oneOf = oneOf {
            components.append("oneOf: \(oneOf)")
        }
        
        return "JSONSchema(\(components.joined(separator: ", ")))"
    }
}
