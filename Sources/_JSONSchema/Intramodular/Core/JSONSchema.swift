//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension JSONSchema {
    public enum SchemaType: String, Codable, Hashable, Sendable {
        case boolean
        case object
        case array
        case number
        case string
        case integer
    }
}

/// Broad description of the JSON schema. It is agnostic and independent of any programming language.
///
/// Based on: https://json-schema.org/draft/2019-09/json-schema-core.html it implements
/// only concepts used in the `rum-events-format` schemas.
public struct JSONSchema: Hashable, Sendable {
    public var id: String?
    public var title: String?
    public var description: String?
    public var properties: [String: JSONSchema]?
    public var additionalProperties: JSONSchema.AdditionalProperties?
    public var required: [String]?
    public var type: SchemaType?
    public var `enum`: [EnumValue]?
    public var const: SchemaConstant?
    @Indirect
    public var items: JSONSchema?
    public var readOnly: Bool?
    
    /// Reference to another schema.
    /// https://json-schema.org/draft/2019-09/json-schema-core.html#ref
    public var ref: String?
    
    /// Subschemas to be resolved.
    /// https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.9.2.1.1
    public var allOf: [JSONSchema]?
    
    /// Subschemas to be resolved.
    /// https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.9.2.1.2
    public var anyOf: [JSONSchema]?
    
    /// Subschemas to be resolved.
    /// https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.9.2.1.3
    public var oneOf: [JSONSchema]?
    
    fileprivate init() {
        
    }
}

extension JSONSchema {
    public subscript(
        property name: String
    ) -> JSONSchema? {
        get {
            self.properties?[name]
        } set {
            self.properties![name] = newValue
        }
    }
}

// MARK: - Conformances

extension JSONSchema: Codable {
    public enum CodingKeys: String, CodingKey, CodingKeyRepresentable {
        case id = "$id"
        case title = "title"
        case description = "description"
        case properties = "properties"
        case additionalProperties = "additionalProperties"
        case required = "required"
        case type = "type"
        case `enum` = "enum"
        case const = "const"
        case items = "items"
        case readOnly = "readOnly"
        case ref = "$ref"
        case oneOf = "oneOf"
        case anyOf = "anyOf"
        case allOf = "allOf"
    }
    
    public init(from decoder: Decoder) throws {
        do {
            // First try decoding with keyed container
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try keyedContainer.decodeIfPresent(String.self, forKey: .id)
            self.title = try keyedContainer.decodeIfPresent(String.self, forKey: .title)
            self.description = try keyedContainer.decodeIfPresent(String.self, forKey: .description)
            self.properties = try keyedContainer.decodeIfPresent([String: JSONSchema].self, forKey: .properties)
            self.additionalProperties = try keyedContainer.decodeIfPresent(JSONSchema.AdditionalProperties.self, forKey: .additionalProperties)
            self.required = try keyedContainer.decodeIfPresent([String].self, forKey: .required)
            self.type = try keyedContainer.decodeIfPresent(SchemaType.self, forKey: .type)
            self.enum = try keyedContainer.decodeIfPresent([EnumValue].self, forKey: .enum)
            self.const = try keyedContainer.decodeIfPresent(SchemaConstant.self, forKey: .const)
            self.items = try keyedContainer.decodeIfPresent(JSONSchema.self, forKey: .items)
            self.readOnly = try keyedContainer.decodeIfPresent(Bool.self, forKey: .readOnly)
            self.ref = try keyedContainer.decodeIfPresent(String.self, forKey: .ref)
            self.allOf = try keyedContainer.decodeIfPresent([JSONSchema].self, forKey: .allOf)
            self.oneOf = try keyedContainer.decodeIfPresent([JSONSchema].self, forKey: .oneOf)
            self.anyOf = try keyedContainer.decodeIfPresent([JSONSchema].self, forKey: .anyOf)
            
            // RUMM-2266 Patch:
            // If schema doesn't define `type`, but defines `properties`, it is safe to assume
            // that its `.object` schema:
            if self.type == nil && self.properties != nil {
                self.type = .object
            }
        } catch let keyedContainerError as DecodingError {
            // If data in this `decoder` cannot be represented as keyed container, perhaps it encodes
            // a single value. Check known schema values:
            do {
                if decoder.codingPath.last as? JSONSchema.CodingKeys == .additionalProperties {
                    // Handle `additionalProperties: true | false`
                    let singleValueContainer = try decoder.singleValueContainer()
                    let hasAdditionalProperties = try singleValueContainer.decode(Bool.self)
                    
                    if hasAdditionalProperties {
                        self.type = .object
                    } else {
                        throw Exception.moreContext(
                            "Decoding `additionalProperties: false` is not supported in `JSONSchema.init(from:)`.",
                            for: keyedContainerError
                        )
                    }
                } else {
                    throw Exception.moreContext(
                        "Decoding \(decoder.codingPath) is not supported in `JSONSchema.init(from:)`.",
                        for: keyedContainerError
                    )
                }
            } catch let singleValueContainerError {
                throw Exception.moreContext(
                    "Unhandled parsing exception in `JSONSchema.init(from:)`.",
                    for: singleValueContainerError
                )
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode simple properties directly
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(properties, forKey: .properties)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(readOnly, forKey: .readOnly)
        try container.encodeIfPresent(ref, forKey: .ref)
        try container.encodeIfPresent(allOf, forKey: .allOf)
        try container.encodeIfPresent(anyOf, forKey: .anyOf)
        try container.encodeIfPresent(oneOf, forKey: .oneOf)
        
        // Encode `enum`
        if let enums = self.enum {
            try container.encode(enums, forKey: .enum)
        }
        
        // Encode `const` using the custom encoding logic of `SchemaConstant`
        try container.encodeIfPresent(const, forKey: .const)
        
        // Explicitly handle `additionalProperties`. Encoding true/false directly or the schema if available.
        if let additionalProperties = self.additionalProperties {
            try container.encode(additionalProperties, forKey: .additionalProperties)
        } else {
            // Since `additionalProperties` was not specified, it's omitted to avoid assuming a default behavior.
            // The behavior here is adjusted to not explicitly encode a default value,
            // adhering to JSON Schema's interpretation norms.
            assert(self.additionalProperties == nil)
        }
        
        // Encode `items` using the custom encoding logic if present
        try container.encodeIfPresent(items, forKey: .items)
    }
}

extension JSONSchema: MergeOperatable {
    /// Merges all attributes of `otherSchema` into this schema.
    public mutating func mergeInPlace(
        with otherSchema: JSONSchema
    ) {
        // Title can be overwritten
        self.title = self.title ?? otherSchema.title
        
        // Description can be overwritten
        self.description = self.description ?? otherSchema.description
        
        // Type can be inferred
        self.type = self.type ?? otherSchema.type
        
        // Properties are accumulated and if both schemas have a property with the same name, property
        // schemas are merged.
        if let selfProperties = self.properties, let otherProperties = otherSchema.properties {
            self.properties = selfProperties.merging(otherProperties) { selfProperty, otherProperty in
                var selfProperty = selfProperty
                selfProperty.mergeInPlace(with: otherProperty)
                return selfProperty
            }
        } else {
            self.properties = self.properties ?? otherSchema.properties
        }
        
        self.additionalProperties = self.additionalProperties ?? otherSchema.additionalProperties
        
        // Required properties are accumulated.
        if let selfRequired = self.required, let otherRequired = otherSchema.required {
            self.required = selfRequired + otherRequired
        } else {
            self.required = self.required ?? otherSchema.required
        }
        
        // Enumeration values are accumulated.
        if let selfEnum = self.enum, let otherEnum = otherSchema.enum {
            self.enum = selfEnum + otherEnum
        } else {
            self.enum = self.enum ?? otherSchema.enum
        }
        
        // Constant value can be overwritten.
        self.const = self.const ?? otherSchema.const
        
        // If both schemas have Items, their schemas are merged.
        // Otherwise, any non-nil Items schema is taken.
        if var selfItems = self.items, let otherItems = otherSchema.items {
            selfItems.mergeInPlace(with: otherItems)
            
            self.items = selfItems
        } else {
            self.items = self.items ?? otherSchema.items
        }
        
        // If both schemas define read-only value, the most strict is taken.
        if let selfReadOnly = self.readOnly, let otherReadOnly = otherSchema.readOnly {
            self.readOnly = selfReadOnly || otherReadOnly
        } else {
            self.readOnly = self.readOnly ?? otherSchema.readOnly
        }
        
        // Accumulate `oneOf` schemas
        if let selfOneOf = oneOf, let otherOneOf = otherSchema.oneOf {
            self.oneOf = selfOneOf + otherOneOf
        } else if let otherOneOf = otherSchema.oneOf {
            self.oneOf = otherOneOf
        }
        
        // Accumulate `anyOf` schemas
        if let selfAnyOf = anyOf, let otherAnyOf = otherSchema.anyOf {
            self.anyOf = selfAnyOf + otherAnyOf
        } else if let otherAnyOf = otherSchema.anyOf {
            self.anyOf = otherAnyOf
        }
    }
}

// MARK: - Internal

extension Array where Element == JSONSchema.EnumValue {
    func inferrSchemaType() -> JSONSchema.SchemaType? {
        let hasOnlyStrings = allSatisfy { element in
            if case .string = element {
                return true
            }
            return false
        }
        if hasOnlyStrings {
            return .string
        }
        
        let hasOnlyIntegers = allSatisfy { element in
            if case .integer = element {
                return true
            }
            return false
        }
        if hasOnlyIntegers {
            return .number
        }
        
        return nil
    }
}

