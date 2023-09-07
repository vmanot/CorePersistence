//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol IdentifierProtocol: Hashable, IdentityRepresentation {
    
}

public protocol UniversallyUniqueIdentifier: IdentifierProtocol, Sendable {
    
}

// MARK: - Implemented Conformances

extension UUID: UniversallyUniqueIdentifier {
    
}
