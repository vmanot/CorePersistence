//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

/// A type that provides a rich representation of its `Swift.Codable` conformance via a `CorePersistence.CodingRepresentation` compliant type.
public protocol _CodingRepresentationProvider: Codable {
    associatedtype CodingRepresentationType: CodingRepresentation<Self>
    
    static var codingRepresentation: CodingRepresentationType { get }
}

extension _CodingRepresentationProvider {
    public static func _resolveCodingRepresentation() throws -> _ResolvedCodingRepresentation {
        try cast(codingRepresentation, to: (any _PrimitiveCodingRepresentation).self).__conversion()
    }
}
