//
// Copyright (c) Vatsal Manot
//

import CoreTransferable
import FoundationX
import Swallow

public protocol PersistenceRepresentation {
    associatedtype Body: PersistenceRepresentation
    
    var body: Body { get }
}

public protocol PersistenceRepresentable {
    associatedtype PersistenceRepresentationType: PersistenceRepresentation
    
    @PersistenceRepresentationBuilder
    static var persistenceRepresentation: PersistenceRepresentationType { get }
}

@_spi(Internal)
public protocol _PersistenceRepresentationBuiltin {
    typealias Context = _PersistentRepresentationResolutionContext
    
    @_spi(Internal)
    func _resolve(
        into representation: inout _ResolvedPersistentRepresentation,
        context: Context
    ) throws
}

// MARK: - Conformees

extension Never: PersistenceRepresentation {
    @_implements(PersistenceRepresentation, body)
    public var _PersistenceRepresentation_body: Never {
        fatalError()
    }
}

extension _PersistenceRepresentationBuiltin {
    public var body: Never {
        fatalError()
    }
}

public struct _PersistentRepresentationResolutionContext {
    public var sourceList: [Weak<any PersistenceRepresentable>] = []
    
    public init() {
        
    }
}
