//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public protocol PersistentIdentifierConvertible {
    associatedtype PersistentID: Codable, Hashable, Sendable
    
    var persistentID: PersistentID { get }
}

public protocol PersistentIdentifierMutable {
    associatedtype PersistentID: Codable, Hashable, Sendable
    
    var persistentID: PersistentID { get }
}

public struct CSSearchableItemID: PersistentIdentifier, Sendable {
    public let uniqueIdentifier: String
    public let domainIdentifier: String?
    
    public var body: some IdentityRepresentation {
        _StringIdentityRepresentation((domainIdentifier.map({ $0 + "." }) ?? "") + uniqueIdentifier)
    }
}
