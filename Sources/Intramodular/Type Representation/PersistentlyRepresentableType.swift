//
// Copyright (c) Vatsal Manot
//

import Swift

/// Defines a type identifier that uniquely identifies a type. This is useful for maintaining the identity of a type, even when its type name is changed.
public protocol PersistentlyRepresentableType {
    associatedtype TypeRepresentation: IdentityRepresentation
    
    /// An identifier that uniquely identifies this type.
    static var persistentTypeRepresentation: TypeRepresentation { get }
}
