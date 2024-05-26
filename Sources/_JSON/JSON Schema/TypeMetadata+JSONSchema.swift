//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Runtime

extension JSONSchema {
    public init(
        type: Any.Type,
        description: String? = nil,
        propertyDescriptions: [String: String]? = nil
    ) throws {
        self = try TypeMetadata(type)._toJSONSchema()
        
        self.description = description
        
        for (propertyName, propertyDescription) in (propertyDescriptions ?? [:]) {
            self[property: propertyName]?.description = propertyDescription
        }
    }
    
    public init(
        type: Any.Type,
        description: String? = nil,
        propertyDescriptions: [String: String]? = nil,
        required: [String]?
    ) throws {
        self = try TypeMetadata(type)._toJSONSchema()
        
        self.description = description
        
        for (propertyName, propertyDescription) in (propertyDescriptions ?? [:]) {
            self[property: propertyName]?.description = propertyDescription
        }
        
        self.required = required
    }
    
    public init(
        type: Any.Type,
        description: String? = nil,
        propertyDescriptions: [String: String]? = nil,
        required: Bool
    ) throws {
        self = try TypeMetadata(type)._toJSONSchema()
        
        self.description = description
        
        for (propertyName, propertyDescription) in (propertyDescriptions ?? [:]) {
            self[property: propertyName]?.description = propertyDescription
        }
        
        self.required = required ? (properties?.keys).map({ Array($0) }) : nil
    }
}

extension TypeMetadata {
    public func _toJSONSchema() throws -> JSONSchema {
        try _tryAssert(base is Codable.Type)
        try _tryAssert(base is any Hashable.Type)

        let base = _getUnwrappedType(from: base)
        
        switch base {
            case is Bool.Type:
                return JSONSchema(type: .boolean)
            case is String.Type:
                return JSONSchema(type: .string)
            case is Int8.Type, is Int16.Type, is Int32.Type, is Int64.Type, is Int.Type:
                return JSONSchema(type: .integer)
            case is UInt8.Type, is UInt16.Type, is UInt32.Type, is UInt64.Type, is UInt.Type:
                return JSONSchema(type: .integer)
            case is Float.Type, is Double.Type:
                return JSONSchema(type: .number)
            default:
                break
        }
        
        if let type = TypeMetadata.Enumeration(base) {
            _ = type
            
            throw Never.Reason.unsupported
        } else if let type = TypeMetadata.Nominal(base) {
            var properties: [String: JSONSchema] = [:]
            var requiredProperties: [String: JSONSchema] = [:]

            for field in type.fields {
                let isOptional = _isTypeOptionalType(field.type.base)
                let fieldType = TypeMetadata(_getUnwrappedType(from: field.type.base))
                
                if isOptional {
                    properties[field.name] = try fieldType._toJSONSchema()
                } else {
                    requiredProperties[field.name] = try fieldType._toJSONSchema()
                }
            }
            
            return JSONSchema(
                type: .object,
                properties: properties.merging(uniqueKeysWithValues: requiredProperties),
                required: Array(requiredProperties.keys)
            )
        } else {
            throw Never.Reason.unsupported
        }
    }
}

extension TypeMetadata.Nominal.Field {
    public func _toJSONSchema() throws -> JSONSchema {
        let type = _unwrappedType(from: self.type.base)
        let schemaType: JSONSchema.SchemaType
        var itemsSchema: JSONSchema?
        
        switch type {
            case String.self:
                schemaType = .string
            case is (any BinaryInteger).Type:
                schemaType = .integer
            case Bool.self:
                schemaType = .boolean
            case is (any FloatingPoint).Type:
                schemaType = .number
            case let type as any _ArrayProtocol.Type:
                schemaType = .array
                itemsSchema = try TypeMetadata(type._opaque_ArrayProtocol_ElementType)._toJSONSchema()
            default:
                throw Never.Reason.illegal
        }
        
        return JSONSchema(
            type: schemaType,
            description: nil,
            properties: nil,
            required: nil,
            additionalProperties: nil,
            items: itemsSchema
        )
    }
}
