//
// Copyright (c) Vatsal Manot
//

import Swift

/// Defines a type identifier that uniquely identifies a type. This is useful for maintaining the identity of a type, even when its type name is changed.
public protocol PersistentlyRepresentableType {
    associatedtype PersistentTypeRepresentation: IdentityRepresentation
    
    /// An identifier that uniquely identifies this type.
    @IdentityRepresentationBuilder
    static var persistentTypeRepresentation: PersistentTypeRepresentation { get }
}
