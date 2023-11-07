//
// Copyright (c) Vatsal Manot
//

import Swallow

public enum PersistenceRepresentations {
    
}

extension PersistenceRepresentations {
    public struct DeduplicateCopy<Item>: PersistenceRepresentation, _PersistenceRepresentationBuiltin {
        public let deduplicate: (Item, Item) throws -> Item
        
        public init(deduplicate: @escaping (Item, Item) throws -> Item) {
            self.deduplicate = deduplicate
        }
        
        @_spi(Internal)
        public func _resolve(
            into representation: inout _ResolvedPersistentRepresentation,
            context: Context
        ) throws {
            representation[Item.self].deduplicateCopy = self
        }
    }
}

extension PersistenceRepresentable {
    public typealias DeduplicateCopy = PersistenceRepresentations.DeduplicateCopy<Self>
}
