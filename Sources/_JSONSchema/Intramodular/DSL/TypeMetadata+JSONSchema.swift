//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Runtime
import Swallow

extension TypeMetadata {
    fileprivate struct JSONSchemaConversionContext {
        let type: TypeMetadata
        let path: CodingPath
        
        let containerPrototype: TypeMetadata._InstancePrototype<any Codable>?
        let containerRelativeFieldPrototype: TypeMetadata._InstancePrototype<any Codable>.Field?
        let instancePrototype: TypeMetadata._InstancePrototype<any Codable>?
        
        var schemaAnnotations: [any _JSONSchemaAnnotationProtocol] {
            var result: [any _JSONSchemaAnnotationProtocol] = []
            
            if let annotation = containerRelativeFieldPrototype?.propertyWrapperMirror?.subject as? any _JSONSchemaAnnotationProtocol {
                result.append(annotation)
            }
            
            return result
        }
        
        private init(
            type: TypeMetadata,
            path: CodingPath,
            containerPrototype: TypeMetadata._InstancePrototype<any Codable>?,
            containerRelativeFieldPrototype: TypeMetadata._InstancePrototype<any Codable>.Field?,
            instancePrototype: TypeMetadata._InstancePrototype<any Codable>?
        ) {
            self.type = type
            self.path = path
            self.containerPrototype = containerPrototype
            self.containerRelativeFieldPrototype = containerRelativeFieldPrototype
            self.instancePrototype = instancePrototype
        }
        
        init<T>(
            reflecting type: T.Type
        ) throws {
            self.init(
                type: TypeMetadata(type),
                path: [],
                containerPrototype: nil,
                containerRelativeFieldPrototype: nil,
                instancePrototype: try TypeMetadata._InstancePrototype<any Codable>(reflecting: type)
            )
        }
        
        func nestedContainer(
            forField field: NominalTypeMetadata.Field
        ) throws -> Self {
            let instancePrototype: TypeMetadata._InstancePrototype<any Codable> = try instancePrototype.unwrap()
            let fieldPrototype = try instancePrototype[field: field.key]
            
            return Self(
                type: field.type,
                path: path.appending(fieldPrototype.key),
                containerPrototype: instancePrototype,
                containerRelativeFieldPrototype: fieldPrototype,
                instancePrototype: nil
            )
        }
    }
}

extension TypeMetadata {
    fileprivate func _reflectJSONSchema(
        context: JSONSchemaConversionContext
    ) throws -> JSONSchema {
        assert(context.type == self)
        
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
            
            try type.fields.forEach { (field:  NominalTypeMetadata.Field) in
                let subcontext: TypeMetadata.JSONSchemaConversionContext = try context.nestedContainer(forField: field)
                let isOptional: Bool = _isTypeOptionalType(field.type.base)
                let fieldKey: AnyCodingKey = try subcontext.containerRelativeFieldPrototype.unwrap().key
                
                var schema: JSONSchema = try field._reflectJSONSchema(context: subcontext)
                
                if isOptional {
                    properties[fieldKey.stringValue] = schema
                } else {
                    requiredProperties[fieldKey.stringValue] = schema
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
    fileprivate func _reflectJSONSchema(
        context: TypeMetadata.JSONSchemaConversionContext
    ) throws -> JSONSchema {
        let type: Any.Type = try context.containerRelativeFieldPrototype.unwrap().unwrappedValueType.base
        let schemaType: JSONSchema.SchemaType
        let itemsSchema: JSONSchema?
        
        switch type {
            case String.self:
                schemaType = .string
                itemsSchema = nil
            case is any BinaryInteger.Type:
                schemaType = .integer
                itemsSchema = nil
            case Bool.self:
                schemaType = .boolean
                itemsSchema = nil
            case is any FloatingPoint.Type:
                schemaType = .number
                itemsSchema = nil
            case let type as any _ArrayProtocol.Type:
                schemaType = .array
                itemsSchema = try TypeMetadata(type._opaque_ArrayProtocol_ElementType)._reflectJSONSchema(context: context)
            default:
                throw Never.Reason.illegal
        }
        
        var result = JSONSchema(
            type: schemaType,
            description: nil,
            properties: nil,
            required: nil,
            additionalProperties: nil,
            items: itemsSchema
        )
        
        try context.schemaAnnotations.forEach({
            try $0._annotate(path: [], in: &result)
        })
        
        return result
    }
    
    private func _primitiveTypeToJSONSchemaType(
        _ type: Any.Type
    ) -> JSONSchema.SchemaType? {
        let schemaType: JSONSchema.SchemaType
        
        switch type {
            case is Bool.Type:
                schemaType = .boolean
            case is String.Type:
                schemaType = .string
            case is Int8.Type, is Int16.Type, is Int32.Type, is Int64.Type, is Int.Type:
                schemaType = .integer
            case is UInt8.Type, is UInt16.Type, is UInt32.Type, is UInt64.Type, is UInt.Type:
                schemaType = .integer
            case is Float.Type, is Double.Type:
                schemaType = .number
            case is any BinaryInteger.Type:
                schemaType = .integer
            case is any FloatingPoint.Type:
                schemaType = .number
            case let type as any _ArrayProtocol.Type:
                schemaType = .array
                
                _ = type
            default:
                return nil
        }
        
        return schemaType
    }
}

extension JSONSchema {
    public protocol _SchemaTypeHinting {
        static var readableJSONSchemaTypes: [JSONSchema.SchemaType] { get }
        static var writableJSONSchemaTypes: [JSONSchema.SchemaType] { get }
    }
}

extension Calendar.Date: JSONSchema._SchemaTypeHinting {
    public static var readableJSONSchemaTypes: [JSONSchema.SchemaType] {
        [.string]
    }
    
    public static var writableJSONSchemaTypes: [JSONSchema.SchemaType] {
        [.string]
    }
}

// MARK: - Supplementary

extension JSONSchema {
    public init<T>(
        reflecting type: T.Type,
        description: String? = nil,
        propertyDescriptions: [String: String]? = nil,
        required: Either<[String], Bool>? = nil
    ) throws {
        let context = try TypeMetadata.JSONSchemaConversionContext(reflecting: type)
        
        self = try TypeMetadata(type)._reflectJSONSchema(context: context)
        
        self.description = description
        
        for (propertyName, propertyDescription) in (propertyDescriptions ?? [:]) {
            self[property: propertyName]?.description = propertyDescription
        }
        
        if let required {
            switch required {
                case .left(let required):
                    self.required = required
                case .right(let required):
                    self.required = required ? (self.properties?.keys).map({ Array($0) }) : nil
            }
        }
    }
    
    public init<T>(
        reflecting type: T.Type,
        description: String? = nil,
        propertyDescriptions: [String: String]? = nil,
        required: Bool
    ) throws {
        try self.init(
            reflecting: type,
            description: description,
            propertyDescriptions: propertyDescriptions,
            required: .right(required)
        )
    }
}
