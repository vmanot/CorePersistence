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

extension _CodingRepresentatable {
    public typealias CodingKeyAlias = CodingRepresentationBuilder<Self>.CodingKeyAlias
}

extension Never: CodingRepresentation {
    
}
