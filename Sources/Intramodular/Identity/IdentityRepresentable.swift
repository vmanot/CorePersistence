//
// Copyright (c) Vatsal Manot
//

import Swift

public protocol IdentityRepresentable {
    associatedtype IdentityRepresentation: CorePersistence.IdentityRepresentation
    
    var identityRepresentation: IdentityRepresentation { get }
}
