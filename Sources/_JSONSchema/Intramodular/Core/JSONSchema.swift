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
        case null
    }
}

/// Broad description of the JSON schema. It is agnostic and independent of any programming language.
///
/// The representation follows JSON Schema Draft 2020-12 and models its common
/// structural and validation vocabulary. A Boolean schema is represented by
/// `booleanValue`; all object-schema properties are `nil` in that form.
public struct JSONSchema: Hashable, Sendable {
    public var booleanValue: Bool? = nil
    public var dialect: String? = nil
    public var id: String? = nil
    public var title: String? = nil
    public var description: String? = nil
    public var definitions: [String: JSONSchema]? = nil
    public var properties: [String: JSONSchema]? = nil
    public var patternProperties: [String: JSONSchema]? = nil
    public var additionalProperties: JSONSchema.AdditionalProperties? = nil
    public var required: [String]? = nil
    public var dependentRequired: [String: [String]]? = nil
    public var dependentSchemas: [String: JSONSchema]? = nil
    @Indirect
    public var propertyNames: JSONSchema? = nil
    public var minProperties: Int? = nil
    public var maxProperties: Int? = nil
    public var type: SchemaType? = nil
    /// The union form of `type`. `type` remains the source-compatible spelling
    /// for a single allowed JSON type.
    public var types: [SchemaType]? = nil
    public var `enum`: [EnumValue]? = nil
    public var const: SchemaConstant? = nil
    @Indirect
    public var items: JSONSchema? = nil
    public var prefixItems: [JSONSchema]? = nil
    @Indirect
    public var contains: JSONSchema? = nil
    public var minContains: Int? = nil
    public var maxContains: Int? = nil
    public var minItems: Int? = nil
    public var maxItems: Int? = nil
    public var uniqueItems: Bool? = nil
    public var minLength: Int? = nil
    public var maxLength: Int? = nil
    public var pattern: String? = nil
    public var format: String? = nil
    public var minimum: Double? = nil
    public var maximum: Double? = nil
    public var exclusiveMinimum: Double? = nil
    public var exclusiveMaximum: Double? = nil
    public var multipleOf: Double? = nil
    public var readOnly: Bool? = nil
    public var writeOnly: Bool? = nil

    /// Reference to another schema.
    /// https://json-schema.org/draft/2020-12/json-schema-core.html#ref
    public var ref: String? = nil

    /// Every subschema must validate successfully.
    /// https://json-schema.org/draft/2020-12/json-schema-core.html
    public var allOf: [JSONSchema]? = nil

    /// At least one subschema must validate successfully.
    /// https://json-schema.org/draft/2020-12/json-schema-core.html
    public var anyOf: [JSONSchema]? = nil

    /// Exactly one subschema must validate successfully.
    /// https://json-schema.org/draft/2020-12/json-schema-core.html
    public var oneOf: [JSONSchema]? = nil

    @Indirect
    public var not: JSONSchema? = nil
    @Indirect
    public var condition: JSONSchema? = nil
    @Indirect
    public var then: JSONSchema? = nil
    @Indirect
    public var `else`: JSONSchema? = nil

    public init() {

    }
}

extension JSONSchema {
    public subscript(
        property name: String
    ) -> JSONSchema? {
        get {
            self.properties?[name]
        }
        set {
            self.properties![name] = newValue
        }
    }
}

// MARK: - Conformances

extension JSONSchema: Codable {
    public enum CodingKeys: String, CodingKey, CodingKeyRepresentable {
        case dialect = "$schema"
        case id = "$id"
        case title = "title"
        case description = "description"
        case definitions = "$defs"
        case properties = "properties"
        case patternProperties = "patternProperties"
        case additionalProperties = "additionalProperties"
        case required = "required"
        case dependentRequired = "dependentRequired"
        case dependentSchemas = "dependentSchemas"
        case propertyNames = "propertyNames"
        case minProperties = "minProperties"
        case maxProperties = "maxProperties"
        case type = "type"
        case `enum` = "enum"
        case const = "const"
        case items = "items"
        case prefixItems = "prefixItems"
        case contains = "contains"
        case minContains = "minContains"
        case maxContains = "maxContains"
        case minItems = "minItems"
        case maxItems = "maxItems"
        case uniqueItems = "uniqueItems"
        case minLength = "minLength"
        case maxLength = "maxLength"
        case pattern = "pattern"
        case format = "format"
        case minimum = "minimum"
        case maximum = "maximum"
        case exclusiveMinimum = "exclusiveMinimum"
        case exclusiveMaximum = "exclusiveMaximum"
        case multipleOf = "multipleOf"
        case readOnly = "readOnly"
        case writeOnly = "writeOnly"
        case ref = "$ref"
        case oneOf = "oneOf"
        case anyOf = "anyOf"
        case allOf = "allOf"
        case not = "not"
        case condition = "if"
        case then = "then"
        case `else` = "else"
    }

    public init(from decoder: Decoder) throws {
        self.init()

        if let container = try? decoder.singleValueContainer(),
            let value = try? container.decode(Bool.self)
        {
            booleanValue = value
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        dialect = try container.decodeIfPresent(String.self, forKey: .dialect)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        definitions = try container.decodeIfPresent([String: JSONSchema].self, forKey: .definitions)
        properties = try container.decodeIfPresent([String: JSONSchema].self, forKey: .properties)
        patternProperties = try container.decodeIfPresent(
            [String: JSONSchema].self, forKey: .patternProperties)
        additionalProperties = try container.decodeIfPresent(
            AdditionalProperties.self, forKey: .additionalProperties)
        required = try container.decodeIfPresent([String].self, forKey: .required)
        dependentRequired = try container.decodeIfPresent(
            [String: [String]].self, forKey: .dependentRequired)
        dependentSchemas = try container.decodeIfPresent(
            [String: JSONSchema].self, forKey: .dependentSchemas)
        propertyNames = try container.decodeIfPresent(JSONSchema.self, forKey: .propertyNames)
        minProperties = try container.decodeIfPresent(Int.self, forKey: .minProperties)
        maxProperties = try container.decodeIfPresent(Int.self, forKey: .maxProperties)
        if let value = try? container.decodeIfPresent(SchemaType.self, forKey: .type) {
            type = value
        } else {
            types = try container.decodeIfPresent([SchemaType].self, forKey: .type)
        }
        self.enum = try container.decodeIfPresent([EnumValue].self, forKey: .enum)
        const = try container.decodeIfPresent(SchemaConstant.self, forKey: .const)
        items = try container.decodeIfPresent(JSONSchema.self, forKey: .items)
        prefixItems = try container.decodeIfPresent([JSONSchema].self, forKey: .prefixItems)
        contains = try container.decodeIfPresent(JSONSchema.self, forKey: .contains)
        minContains = try container.decodeIfPresent(Int.self, forKey: .minContains)
        maxContains = try container.decodeIfPresent(Int.self, forKey: .maxContains)
        minItems = try container.decodeIfPresent(Int.self, forKey: .minItems)
        maxItems = try container.decodeIfPresent(Int.self, forKey: .maxItems)
        uniqueItems = try container.decodeIfPresent(Bool.self, forKey: .uniqueItems)
        minLength = try container.decodeIfPresent(Int.self, forKey: .minLength)
        maxLength = try container.decodeIfPresent(Int.self, forKey: .maxLength)
        pattern = try container.decodeIfPresent(String.self, forKey: .pattern)
        format = try container.decodeIfPresent(String.self, forKey: .format)
        minimum = try container.decodeIfPresent(Double.self, forKey: .minimum)
        maximum = try container.decodeIfPresent(Double.self, forKey: .maximum)
        exclusiveMinimum = try container.decodeIfPresent(Double.self, forKey: .exclusiveMinimum)
        exclusiveMaximum = try container.decodeIfPresent(Double.self, forKey: .exclusiveMaximum)
        multipleOf = try container.decodeIfPresent(Double.self, forKey: .multipleOf)
        readOnly = try container.decodeIfPresent(Bool.self, forKey: .readOnly)
        writeOnly = try container.decodeIfPresent(Bool.self, forKey: .writeOnly)
        ref = try container.decodeIfPresent(String.self, forKey: .ref)
        allOf = try container.decodeIfPresent([JSONSchema].self, forKey: .allOf)
        oneOf = try container.decodeIfPresent([JSONSchema].self, forKey: .oneOf)
        anyOf = try container.decodeIfPresent([JSONSchema].self, forKey: .anyOf)
        not = try container.decodeIfPresent(JSONSchema.self, forKey: .not)
        condition = try container.decodeIfPresent(JSONSchema.self, forKey: .condition)
        then = try container.decodeIfPresent(JSONSchema.self, forKey: .then)
        self.else = try container.decodeIfPresent(JSONSchema.self, forKey: .else)
    }

    public func encode(to encoder: Encoder) throws {
        if let booleanValue {
            var container = encoder.singleValueContainer()
            try container.encode(booleanValue)
            return
        }

        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(dialect, forKey: .dialect)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(definitions, forKey: .definitions)
        try container.encodeIfPresent(properties, forKey: .properties)
        try container.encodeIfPresent(patternProperties, forKey: .patternProperties)
        try container.encodeIfPresent(additionalProperties, forKey: .additionalProperties)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(dependentRequired, forKey: .dependentRequired)
        try container.encodeIfPresent(dependentSchemas, forKey: .dependentSchemas)
        try container.encodeIfPresent(propertyNames, forKey: .propertyNames)
        try container.encodeIfPresent(minProperties, forKey: .minProperties)
        try container.encodeIfPresent(maxProperties, forKey: .maxProperties)
        if let types {
            try container.encode(types, forKey: .type)
        } else {
            try container.encodeIfPresent(type, forKey: .type)
        }
        try container.encodeIfPresent(self.enum, forKey: .enum)
        try container.encodeIfPresent(const, forKey: .const)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(prefixItems, forKey: .prefixItems)
        try container.encodeIfPresent(contains, forKey: .contains)
        try container.encodeIfPresent(minContains, forKey: .minContains)
        try container.encodeIfPresent(maxContains, forKey: .maxContains)
        try container.encodeIfPresent(minItems, forKey: .minItems)
        try container.encodeIfPresent(maxItems, forKey: .maxItems)
        try container.encodeIfPresent(uniqueItems, forKey: .uniqueItems)
        try container.encodeIfPresent(minLength, forKey: .minLength)
        try container.encodeIfPresent(maxLength, forKey: .maxLength)
        try container.encodeIfPresent(pattern, forKey: .pattern)
        try container.encodeIfPresent(format, forKey: .format)
        try container.encodeIfPresent(minimum, forKey: .minimum)
        try container.encodeIfPresent(maximum, forKey: .maximum)
        try container.encodeIfPresent(exclusiveMinimum, forKey: .exclusiveMinimum)
        try container.encodeIfPresent(exclusiveMaximum, forKey: .exclusiveMaximum)
        try container.encodeIfPresent(multipleOf, forKey: .multipleOf)
        try container.encodeIfPresent(readOnly, forKey: .readOnly)
        try container.encodeIfPresent(writeOnly, forKey: .writeOnly)
        try container.encodeIfPresent(ref, forKey: .ref)
        try container.encodeIfPresent(allOf, forKey: .allOf)
        try container.encodeIfPresent(anyOf, forKey: .anyOf)
        try container.encodeIfPresent(oneOf, forKey: .oneOf)
        try container.encodeIfPresent(not, forKey: .not)
        try container.encodeIfPresent(condition, forKey: .condition)
        try container.encodeIfPresent(then, forKey: .then)
        try container.encodeIfPresent(self.else, forKey: .else)
    }
}

extension JSONSchema: MergeOperatable {
    /// Merges all attributes of `otherSchema` into this schema.
    public mutating func mergeInPlace(
        with otherSchema: JSONSchema
    ) {
        self.booleanValue = self.booleanValue ?? otherSchema.booleanValue
        self.dialect = self.dialect ?? otherSchema.dialect
        self.id = self.id ?? otherSchema.id

        // Title can be overwritten
        self.title = self.title ?? otherSchema.title

        // Description can be overwritten
        self.description = self.description ?? otherSchema.description

        // Type can be inferred
        self.type = self.type ?? otherSchema.type
        self.types = self.types ?? otherSchema.types

        self.definitions = mergeSchemas(self.definitions, otherSchema.definitions)

        // Properties are accumulated and if both schemas have a property with the same name, property
        // schemas are merged.
        if let selfProperties = self.properties, let otherProperties = otherSchema.properties {
            self.properties = selfProperties.merging(otherProperties) {
                selfProperty, otherProperty in
                var selfProperty = selfProperty
                selfProperty.mergeInPlace(with: otherProperty)
                return selfProperty
            }
        } else {
            self.properties = self.properties ?? otherSchema.properties
        }

        self.patternProperties = mergeSchemas(
            self.patternProperties,
            otherSchema.patternProperties
        )

        self.additionalProperties = self.additionalProperties ?? otherSchema.additionalProperties

        // Required properties are accumulated.
        if let selfRequired = self.required, let otherRequired = otherSchema.required {
            self.required = selfRequired + otherRequired
        } else {
            self.required = self.required ?? otherSchema.required
        }

        if let dependentRequired, let other = otherSchema.dependentRequired {
            self.dependentRequired = dependentRequired.merging(other) { current, incoming in
                Array(Set(current + incoming))
            }
        } else {
            self.dependentRequired = self.dependentRequired ?? otherSchema.dependentRequired
        }
        self.dependentSchemas = mergeSchemas(
            self.dependentSchemas,
            otherSchema.dependentSchemas
        )
        self.propertyNames = self.propertyNames ?? otherSchema.propertyNames
        self.minProperties = self.minProperties ?? otherSchema.minProperties
        self.maxProperties = self.maxProperties ?? otherSchema.maxProperties

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
        self.prefixItems = self.prefixItems ?? otherSchema.prefixItems
        self.contains = self.contains ?? otherSchema.contains
        self.minContains = self.minContains ?? otherSchema.minContains
        self.maxContains = self.maxContains ?? otherSchema.maxContains
        self.minItems = self.minItems ?? otherSchema.minItems
        self.maxItems = self.maxItems ?? otherSchema.maxItems
        self.uniqueItems = self.uniqueItems ?? otherSchema.uniqueItems
        self.minLength = self.minLength ?? otherSchema.minLength
        self.maxLength = self.maxLength ?? otherSchema.maxLength
        self.pattern = self.pattern ?? otherSchema.pattern
        self.format = self.format ?? otherSchema.format
        self.minimum = self.minimum ?? otherSchema.minimum
        self.maximum = self.maximum ?? otherSchema.maximum
        self.exclusiveMinimum = self.exclusiveMinimum ?? otherSchema.exclusiveMinimum
        self.exclusiveMaximum = self.exclusiveMaximum ?? otherSchema.exclusiveMaximum
        self.multipleOf = self.multipleOf ?? otherSchema.multipleOf

        // If both schemas define read-only value, the most strict is taken.
        if let selfReadOnly = self.readOnly, let otherReadOnly = otherSchema.readOnly {
            self.readOnly = selfReadOnly || otherReadOnly
        } else {
            self.readOnly = self.readOnly ?? otherSchema.readOnly
        }
        if let writeOnly, let other = otherSchema.writeOnly {
            self.writeOnly = writeOnly || other
        } else {
            self.writeOnly = self.writeOnly ?? otherSchema.writeOnly
        }

        self.ref = self.ref ?? otherSchema.ref

        if let allOf, let other = otherSchema.allOf {
            self.allOf = allOf + other
        } else {
            self.allOf = self.allOf ?? otherSchema.allOf
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

        self.not = self.not ?? otherSchema.not
        self.condition = self.condition ?? otherSchema.condition
        self.then = self.then ?? otherSchema.then
        self.else = self.else ?? otherSchema.else
    }
}

private func mergeSchemas(
    _ lhs: [String: JSONSchema]?,
    _ rhs: [String: JSONSchema]?
) -> [String: JSONSchema]? {
    guard let lhs else {
        return rhs
    }
    guard let rhs else {
        return lhs
    }
    return lhs.merging(rhs) { current, incoming in
        var result = current
        result.mergeInPlace(with: incoming)
        return result
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
