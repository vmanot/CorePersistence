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
    }
}

extension AnyPersistentIdentifier: Codable {
    public init(from decoder: Decoder) throws {
        do {
            try self.init(rawValue: UUID(from: decoder))
        } catch {
            runtimeIssue(error)
            
            try self.init(rawValue: String(from: decoder)) // FIXME
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
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
