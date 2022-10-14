//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

/// An encapsulation of all known metadata of a persistently identifiable type.
public struct _PersistentTypeRepresentation: Codable, Hashable {
    public enum Version: String, Codable, Hashable {
        case v0_0_1 = "0.0.1"
    }
    
    public let version: Version
    
    @NonCodingProperty private var _resolvedType: Any.Type?
    
    /// The mangled type name of a Swift type as returned by `_mangledTypeName`.
    public let _swift_mangledTypeName: String?
    public let objCClassName: String?
    
    /// The persistent type identifier of the type (if any).
    public let typeRepresentation: AnyCodable?
    
    public init(from type: Any.Type) {
        self.version = .v0_0_1
        
        self._resolvedType = type
        
        self._swift_mangledTypeName = _mangledTypeName(type)
        self.objCClassName = (type as? AnyObject.Type).map(NSStringFromClass)
        
        if let type = type as? (any PersistentlyRepresentableType.Type) {
            self.typeRepresentation = try? AnyCodable(type.persistentTypeRepresentation)
        } else {
            self.typeRepresentation = nil
        }
    }
}

extension _PersistentTypeRepresentation {
    public func resolveType() throws -> Any.Type {
        if let _resolvedType = _resolvedType {
            return _resolvedType
        } else {
            return try _typeByName(_swift_mangledTypeName.unwrap()).unwrap()
        }
    }
}
