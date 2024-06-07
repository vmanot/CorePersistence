//
// Copyright (c) Vatsal Manot
//

import Foundation
@_spi(Internal) import Swallow

public protocol IdentifierProtocol: Hashable, IdentityRepresentation {
    
}

public protocol UniversallyUniqueIdentifier: IdentifierProtocol, Sendable {
    
}

// MARK: - Implemented Conformances

extension _AutoIncrementingIdentifier: IdentifierProtocol {
    public var body: some IdentityRepresentation {
        _BinaryIntegerIdentityRepresentation(id)
    }
}

extension _TypeAssociatedID: IdentifierProtocol where RawValue: IdentifierProtocol {
    
}

extension _TypeAssociatedID: UniversallyUniqueIdentifier where RawValue: UniversallyUniqueIdentifier {
    
}

extension UUID: UniversallyUniqueIdentifier {
    
}
