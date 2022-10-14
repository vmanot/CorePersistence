//
// Copyright (c) Vatsal Manot
//

import Swallow
import Foundation

/// A type whose _instances_ are semantically versioned.
public protocol SemanticallyVersioned {
    associatedtype Version: SemanticVersionProtocol
    
    var version: Version? { get }
}
