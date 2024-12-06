//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Runtime

extension TypeMetadata {
    /// A prototype instance of a Swift type.
    public struct InstancePrototype<InstanceType> {
        public let type: TypeMetadata
        public let instance: InstanceMirror<InstanceType>
        
        fileprivate init(
            type: TypeMetadata,
            instance: InstanceMirror<InstanceType>
        ) {
            self.type = type
            self.instance = instance
        }
        
        public init<T>(
            reflecting type: T.Type
        ) throws {
            let placeholder = try cast(_generatePlaceholder(ofType: type), to: InstanceType.self)
            
            self.init(
                type: TypeMetadata(type),
                instance: try InstanceMirror<InstanceType>(reflecting: placeholder)
            )
        }
    }
}

extension TypeMetadata {
    fileprivate struct JSONSchemaConversionContext {
        let type: TypeMetadata
        let path: CodingPath
        let superProtoype: TypeMetadata.InstancePrototype<any Codable>?
        let prototype: TypeMetadata.InstancePrototype<any Codable>?
        
        private init(
            type: TypeMetadata,
            path: CodingPath,
            superProtoype: TypeMetadata.InstancePrototype<any Codable>?,
            prototype: TypeMetadata.InstancePrototype<any Codable>?
        ) {
            self.type = type
            self.path = path
            self.superProtoype = superProtoype
            self.prototype = prototype
        }
        
        init<T>(reflecting type: T.Type) throws {
            self.init(
                type: TypeMetadata(type),
                path: [],
                superProtoype: nil,
                prototype: try TypeMetadata.InstancePrototype<any Codable>(reflecting: type)
            )
        }
        
        func nestedContainer(
            forField field: NominalTypeMetadata.Field
        ) -> Self {
            Self(
                type: field.type,
                path: path.appending(field.key),
                superProtoype: prototype,
                prototype: prototype
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
            
            for field in type.fields {
                let subcontext: TypeMetadata.JSONSchemaConversionContext = context.nestedContainer(forField: field)
                
                let isOptional = _isTypeOptionalType(field.type.base)
                let fieldType = TypeMetadata(_getUnwrappedType(from: field.type.base))
                
                if isOptional {
                    properties[field.name] = try fieldType._reflectJSONSchema(context: subcontext)
                } else {
                    requiredProperties[field.name] = try fieldType._reflectJSONSchema(context: subcontext)
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
    private func _reflectJSONSchema(
        context: TypeMetadata.JSONSchemaConversionContext
    ) throws -> JSONSchema {
        let type = _unwrappedType(from: self.type.base)
        let schemaType: JSONSchema.SchemaType
        let itemsSchema: JSONSchema?
        
        var annotations: [any _JSONSchemaAnnotationProtocol.Type] = []
        
        switch type {
            case String.self:
                schemaType = .string
                itemsSchema = nil
            case is (any BinaryInteger).Type:
                schemaType = .integer
                itemsSchema = nil
            case Bool.self:
                schemaType = .boolean
                itemsSchema = nil
            case is (any FloatingPoint).Type:
                schemaType = .number
                itemsSchema = nil
            case let type as any _ArrayProtocol.Type:
                schemaType = .array
                itemsSchema = try TypeMetadata(type._opaque_ArrayProtocol_ElementType)._reflectJSONSchema(context: context)
            case let type as any _JSONSchemaAnnotationProtocol.Type:
                schemaType = try _primitiveTypeToJSONSchemaType(type._opaque_WrappedValue).unwrap()
                itemsSchema = nil
            default:
                throw Never.Reason.illegal
        }
        
        let result = JSONSchema(
            type: schemaType,
            description: nil,
            properties: nil,
            required: nil,
            additionalProperties: nil,
            items: itemsSchema
        )
        
        return result
    }
    
    private func _primitiveTypeToJSONSchemaType(
        _ type: Any.Type
    ) -> JSONSchema.SchemaType? {
        let schemaType: JSONSchema.SchemaType
        
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
