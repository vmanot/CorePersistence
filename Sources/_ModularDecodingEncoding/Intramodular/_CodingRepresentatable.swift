//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol _CodingRepresentatable: Codable {
    associatedtype CodingRepresentationType: CodingRepresentation<Self>
    
    static var codingRepresentation: CodingRepresentationType { get }
}

extension _CodingRepresentatable {
    public static func _dumpCodingRepresentation() throws -> _ResolvedCodingRepresentation {
        try cast(codingRepresentation, to: (any _PrimitiveCodingRepresentation).self).__conversion()
    }
}
