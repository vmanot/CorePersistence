//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

/// A type that represents a semantic version.
public protocol SemanticVersionProtocol: CustomStringConvertible, Codable, Hashable {
    
}

// MARK: - Conformances -

extension FoundationX.Version: SemanticVersionProtocol {
    
}
