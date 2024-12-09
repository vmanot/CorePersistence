//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _JSONSchemaAnnotationProtocol: Codable, Hashable, PropertyWrapper, Sendable {
    func _annotate(
        path: CodingPath,
        in schema: inout JSONSchema
    ) throws
}

@propertyWrapper
public struct _JSONSchemaDescriptionAnnotation<Value: Codable & Hashable & Sendable>: _JSONSchemaAnnotationProtocol {
    public var wrappedValue: Value
    public var description: String?
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init(
        wrappedValue: Value,
        _ description: String
    ) {
        self.wrappedValue = wrappedValue
        self.description = description
    }
    
    public init(
        wrappedValue: Value = .init(),
        _ description: String
    ) where Value: Initiable {
        self.wrappedValue = wrappedValue
        self.description = description
    }
    
    public init(
        wrappedValue: Value = nil,
        _ description: String
    ) where Value: ExpressibleByNilLiteral {
        self.wrappedValue = wrappedValue
        self.description = description
    }
    
    public init(
        wrappedValue: Value = nil,
        _ description: String
    ) where Value: ExpressibleByNilLiteral & Initiable {
        self.wrappedValue = wrappedValue
        self.description = description
    }
    
    public func _annotate(
        path: Swallow.CodingPath,
        in schema: inout JSONSchema
    ) throws {
        schema[path]?.description = description
    }
}

extension Decodable {
    public typealias JSONSchemaDescription<T: Codable & Hashable & Sendable> = _JSONSchemaDescriptionAnnotation<T>
}
