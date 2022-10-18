//
// Copyright (c) Vatsal Manot
//

import Swallow
import Foundation

/// A type whose instances are semantically versioned.
public protocol SemanticallyVersioned {
    associatedtype InstanceVersion: SemanticVersionProtocol
    
    var instanceVersion: InstanceVersion? { get }
}
