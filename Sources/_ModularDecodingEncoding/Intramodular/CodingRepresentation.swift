//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow

//@RepresentationBuilder(for: )
public protocol CodingRepresentation<Item> {
    associatedtype Item: Codable
    associatedtype Body: CodingRepresentation
    
    @CodingRepresentationBuilder<Item>
    var body: Body { get }
}
public protocol _PrimitiveCodingRepresentation: CodingRepresentation where Body == Never {
    func __conversion() throws -> _ResolvedCodingRepresentation
}

extension _PrimitiveCodingRepresentation {
    public var body: Never {
        return fatalError()
    }
}

public protocol _CodingRepresentatable: Codable {
    associatedtype CodingRepresentationType: CodingRepresentation<Self>
    
    static var codingRepresentation: CodingRepresentationType { get }
}

extension _CodingRepresentatable {
    public typealias CodingKeyAlias = CodingRepresentationBuilder<Self>.CodingKeyAlias
}

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
            
            try _tryAssert(primitives.allSatisfy({ $0.itemType == ItemType.self }))
            
            return _ResolvedCodingRepresentation(
                itemType: ItemType.self,
                elements: primitives.flatMap({
                    $0.elements
                })
            )
        }
    }
}

public final class _ResolvedCodingRepresentation {
    @_LockedState private static var representationsByType: [Metatype<any _CodingRepresentatable.Type>: _ResolvedCodingRepresentation] = [:]

    public enum Element: Codable, Hashable, Sendable {
        case codingKeyAlias(AnyCodingKeyAlias)
    }
    
    @_HashableExistential
    public var itemType: any Codable.Type
    public let elements: [Element]
    
    package lazy var keysToKeyAliases: [AnyCodingKey: Set<AnyCodingKey>] = {
        elements
            .compactMap(/Element.codingKeyAlias)
            .flatMap({ [$0, $0.reversed()] })
            .group(by: { element -> AnyCodingKey in
                element.source
            })
            .mapValues({ Set<AnyCodingKey>($0.map({ $0.destination })) })
    }()
    
    public init(
        itemType: any Codable.Type,
        elements: [Element]
    ) {
        self.itemType = itemType
        self.elements = elements
    }
    
    public init(
        itemType: any Codable.Type,
        representation: Element
    ) {
        self.itemType = itemType
        self.elements = [representation]
    }
            
    public static func _for(
        _ type: any _CodingRepresentatable.Type
    ) -> _ResolvedCodingRepresentation {
        _ResolvedCodingRepresentation.representationsByType[Metatype(type), defaultInPlace: try! type._dumpCodingRepresentation()]
    }
}

extension _CodingRepresentatable {
    public static func _dumpCodingRepresentation() throws -> _ResolvedCodingRepresentation {
        try cast(codingRepresentation, to: (any _PrimitiveCodingRepresentation).self).__conversion()
    }
}

extension CodingRepresentationBuilder {
    public struct CodingKeyAlias: _PrimitiveCodingRepresentation {
        public typealias Item = ItemType
        
        private let alias: AnyCodingKeyAlias
        
        public init(alias: AnyCodingKeyAlias) {
            self.alias = alias
        }
                
        public init(source: AnyCodingKey, destination: AnyCodingKey) {
            self.init(alias: AnyCodingKeyAlias(source: source, destination: destination))
        }
        
        public func __conversion() throws -> _ResolvedCodingRepresentation {
            _ResolvedCodingRepresentation(itemType: ItemType.self, representation: .codingKeyAlias(alias))
        }
    }
}

extension Never: CodingRepresentation {
    
}

public struct AnyCodingKeyAlias: Codable, Hashable, Sendable {
    public let source: AnyCodingKey
    public let destination: AnyCodingKey
    
    public init(source: AnyCodingKey, destination: AnyCodingKey) {
        self.source = source
        self.destination = destination
    }
    
    public func reversed() -> Self {
        Self(source: destination, destination: source)
    }
}
