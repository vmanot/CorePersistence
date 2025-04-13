//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow
import SwallowMacrosClient

@resultBuilder
public struct CodingRepresentationBuilder<ItemType: Codable> {
    public typealias BlockType = CodingRepresentation
    
    public static func buildBlock<T: BlockType<ItemType>>(
        _ block: T
    ) -> T {
        block
    }
    
    public static func buildPartialBlock<T: BlockType<ItemType>>(
        first representation: T
    ) -> Accumulated {
        Accumulated([representation])
    }
    
    public static func buildPartialBlock<T: BlockType<ItemType>>(
        accumulated: Accumulated,
        next: T
    ) -> Accumulated  {
        Accumulated(accumulated.base + [next])
    }
}

extension CodingRepresentationBuilder {
    /// This type is a work-in-progress. Do not use this type directly in your code.
    public struct Accumulated: _PrimitiveCodingRepresentation {
        public typealias Item = ItemType
        public typealias Body = Never
        
        var base: [any BlockType]
        
        init(_ base: [any BlockType]) {
            self.base = base.flatMap({ block -> [any BlockType] in
                if let block = block as? Accumulated {
                    return block.base
                } else {
                    return [block]
                }
            })
        }
        
        public func __conversion() throws -> _ResolvedCodingRepresentation {
            let primitives = try base.map({
                try _forceCast($0, to: (any _PrimitiveCodingRepresentation).self).__conversion()
            })
            
            try #assert(primitives.allSatisfy({ $0.itemType == ItemType.self }))
            
            return _ResolvedCodingRepresentation(
                itemType: ItemType.self,
                elements: primitives.flatMap({
                    $0.elements
                })
            )
        }
    }
}
