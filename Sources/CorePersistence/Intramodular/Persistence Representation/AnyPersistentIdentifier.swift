//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct AnyPersistentIdentifier: Hashable, Sendable {
    public typealias RawValue = any Codable & Hashable & Sendable
    
    @_UnsafelySerialized
    public var rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
        
        assert(!_isValueNil(_unwrapPossiblyTypeErasedValue(rawValue)))
    }
    
    public init<T: Codable & Hashable & Sendable>(erasing value: T) {
        if let value = value as? AnyPersistentIdentifier {
            self = value
        } else {
            self.init(rawValue: value)
        }
    }
}

extension AnyPersistentIdentifier {
    public func `as`<T>(_ type: T.Type) throws -> T {
        if type == AnyPersistentIdentifier.self || type == Optional<AnyPersistentIdentifier>.self {
            return self as! T
        } else {
            return try cast(rawValue, to: type)
        }
    }
}

// MARK: - Conformances

extension AnyPersistentIdentifier: CustomStringConvertible {
    public var description: String {
        String(describing: rawValue)
    }
}

extension AnyPersistentIdentifier: Codable {
    public init(from decoder: Decoder) throws {
        do {
            self._rawValue = .init(wrappedValue: try UUID(from: decoder))
        } catch {
            self._rawValue = try _UnsafelySerialized<any Codable & Hashable & Sendable>(from: decoder)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try _rawValue.encode(to: encoder)
    }
}

// MARK: - Supplementary

extension _TypeAssociatedID where RawValue == AnyPersistentIdentifier {
    public init(rawValue: UUID) {
        self.init(rawValue: AnyPersistentIdentifier(rawValue: rawValue))
    }
}

extension _TypeAssociatedID where RawValue == AnyPersistentIdentifier {
    public func `as`<T: PersistentIdentifier>(_ type: T.Type) throws -> T {
        try cast(rawValue, to: type)
    }
}
