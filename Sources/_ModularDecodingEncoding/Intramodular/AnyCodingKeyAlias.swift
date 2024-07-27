//
// Copyright (c) Vatsal Manot
//

import Swallow

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
