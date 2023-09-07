//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

/// A type whose instances are semantically versioned.
public protocol SemanticallyVersioned {
    associatedtype InstanceVersion: SemanticVersionProtocol = Optional<FoundationX.Version>
    
    var instanceVersion: InstanceVersion? { get }
}

// MARK: - Implementation -

extension SemanticallyVersioned where InstanceVersion == Optional<FoundationX.Version> {
    var instanceVersion: InstanceVersion? {
        nil
    }
}
