//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A type that represents a data model.
public protocol Model {
    static var modelVersion: Version? { get }
}
