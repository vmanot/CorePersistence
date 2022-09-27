//
// Copyright (c) Vatsal Manot
//

import Swift

/// Defines a type identifier that uniquely identifies a type. This is useful for maintaining the identity of a type, even when its type name is changed.
public protocol PersistentlyIdentifiableType {
    associatedtype PersistentTypeIdentifier: Codable & LosslessStringConvertible
    
    /// An identifier that uniquely identifies this type.
    static var persistentTypeIdentifier: PersistentTypeIdentifier { get }
}
