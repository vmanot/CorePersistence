//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A one-to-many identifiers map.
@_spi(Internal)
public struct _OneToManyIdentifiersSet<Key: Hashable, ID: Hashable>: Hashable {
    public var identifiersByKey: [Key: Set<ID>] = [:]
    public var keysByIdentifier: [ID: Set<Key>] = [:]
    
    public mutating func insert(_ id: ID, forKey key: Key) {
        identifiersByKey[key, default: []].insert(id)
    }
    
    public mutating func remove(_ id: ID) {
        for key in keysByIdentifier[id] ?? [] {
            identifiersByKey[key, default: []].remove(id)
        }
        
        keysByIdentifier.removeValue(forKey: id)
    }
    
    public mutating func removeAll(keyedBy key: Key) {
        for id in identifiersByKey[key] ?? [] {
            keysByIdentifier[id, default: []].remove(key)
        }
        
        identifiersByKey.removeValue(forKey: key)
    }
    
    public subscript(_ keys: Set<Key>) -> Set<ID> {
        identifiersByKey
            .filter({ keys.contains($0.key) })
            .values
            ._intersection()
    }
    
    public subscript(_ key: Key) -> Set<ID> {
        get {
            identifiersByKey[key, default: []]
        } set {
            let diff = newValue.difference(from: self[key])
            
            guard !diff.isEmpty else {
                return
            }
            
            identifiersByKey[key] = newValue
            
            for id in diff.insertions {
                keysByIdentifier[id, default: []].insert(key)
            }
            
            for id in diff.removals {
                keysByIdentifier[id, default: []].remove(key)
            }
        }
    }
    
    public subscript(_ id: ID) -> Set<Key> {
        get{
            keysByIdentifier[id, default: []]
        } set {
            let diff = newValue.difference(from: self[id])
            
            guard !diff.isEmpty else {
                return
            }
            
            keysByIdentifier[id] = newValue
            
            for key in diff.insertions {
                identifiersByKey[key, default: []].insert(id)
            }
            
            for key in diff.removals {
                identifiersByKey[key, default: []].remove(id)
            }
        }
    }
}

// MARK: - Implemented Conformances

extension _OneToManyIdentifiersSet: Sequence {
    public typealias Element = (key: Key, value: Set<ID>)
    
    public func makeIterator() -> some IteratorProtocol<Element> {
        identifiersByKey.makeIterator()
    }
}
