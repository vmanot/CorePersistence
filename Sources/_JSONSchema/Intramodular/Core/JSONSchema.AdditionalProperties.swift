//
// Copyright (c) Vatsal Manot
//

import Swallow

extension JSONSchema {
    public indirect enum AdditionalProperties: Hashable, Sendable, ExpressibleByBooleanLiteral {
        case boolean(Bool)
        case schema(JSONSchema)
                
        public init(booleanLiteral value: Bool) {
            self = .boolean(value)
        }
        
        public init(_ schema: JSONSchema) {
            self = .schema(schema)
        }
    }
}

// MARK: - Conformances

extension JSONSchema.AdditionalProperties: CustomStringConvertible {
    public var description: String {
        switch self {
            case .boolean(let value):
                return value.description
            case .schema(let schema):
                return String(describing: schema)
        }
    }
}

extension JSONSchema.AdditionalProperties: Codable {
    public init(from decoder: Decoder) throws {
        do {
            self = try .boolean(Bool(from: decoder))
        } catch {
            self = try .schema(JSONSchema(from: decoder))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
            case let .boolean(value):
                try value.encode(to: encoder)
            case let .schema(schema):
                try schema.encode(to: encoder)
        }
    }
}

// MARK: - Supplementary

extension JSONSchema {
    public init?(
        from additionalProperties: JSONSchema.AdditionalProperties
    ) {
        switch additionalProperties {
            case .boolean:
                return nil
            case .schema(let schema):
                self = schema
        }
    }
    
    public mutating func requireAllPropertiesRecursively() {
        switch type {
            case .object:
                self.required = self.properties.map({ Array<String>($0.keys) })
            case .array:
                self.required = self.items?.properties.map({ Array<String>($0.keys) })
            default:
                break
        }

        self.properties?._forEach(mutating: { (element: inout (key: String, value: JSONSchema)) in
            element.value.requireAllPropertiesRecursively()
        })
        self.items?.requireAllPropertiesRecursively()
    }
    
    public mutating func disableAdditionalPropertiesRecursively() {
        switch type {
            case .object:
                self.additionalProperties = .boolean(false)
            case .array:
                self.additionalProperties = .boolean(false)
            default:
                self.additionalProperties = .boolean(false)
        }
        
        self.properties?._forEach(mutating: { (element: inout (key: String, value: JSONSchema)) in
            element.value.disableAdditionalPropertiesRecursively()
        })
        self.items?.disableAdditionalPropertiesRecursively()
    }
}
