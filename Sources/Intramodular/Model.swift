//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A type that represents a data model.
public protocol Model {
    
}

/// A versioned data model.
public protocol VersionedModel: Model {
    associatedtype ModelVersion: SemanticVersionProtocol = Optional<FoundationX.Version>
    
    static var modelVersion: ModelVersion { get }
}

// MARK: - Implementation -

extension VersionedModel where ModelVersion == Optional<FoundationX.Version> {
    public static var modelVersion: ModelVersion {
        nil
    }
}
