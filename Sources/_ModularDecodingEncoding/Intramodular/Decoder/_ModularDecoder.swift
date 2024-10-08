//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct _ModularDecoder: Decoder {
    let base: Decoder
    var configuration: Configuration
    let context: Context
    
    public var codingPath: [CodingKey] {
        base.codingPath
    }
    
    public var userInfo: [CodingUserInfoKey: Any] {
        base.userInfo
    }
    
    init(
        base: Decoder,
        configuration: Configuration?,
        context: Context
    ) {
        if let base = base as? _PolymorphicDecoder, !(context.type is any _PolymorphicDecodingProxyType.Type) {
            self.base = base.base
        } else {
            self.base = base
        }

        self.configuration = configuration ?? nil
        self.context = context
    }
    
    public init(
        wrapping decoder: Decoder
    ) {
        if let decoder = decoder as? Self {
            self = decoder
        } else {
            self.init(base: decoder, configuration: nil, context: .init(type: nil))
        }
    }
    
    public func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(
            KeyedContainer(
                base: try base.container(keyedBy: type),
                decoder: self
            )
        )
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        UnkeyedContainer(
            base: try base.unkeyedContainer(),
            decoder: self
        )
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(
            try base.singleValueContainer(),
            parent: self
        )
    }
}

extension _ModularDecoder {
    public mutating func hideCodingPath<T: CodingKey>(
        _ path: [T]
    ) {
        self.configuration.hiddenCodingPaths.insert(path.map({ AnyCodingKey(erasing: $0) }))
    }
}

// MARK: - Auxiliary

extension _ModularDecoder {
    public struct Configuration: ExpressibleByNilLiteral {
        public var codingPath: [AnyCodingKey] = []
        public var hiddenCodingPaths: Set<[AnyCodingKey]> = []
        public var plugins: [any _ModularCodingPlugin] = []
        
        public var allowsUnsafeSerialization: Bool {
            plugins.contains(where: { $0 is _UnsafeSerializationPlugin })
        }
        
        public init(nilLiteral: ()) {
            
        }
        
        func hides(
            _ key: some CodingKey,
            at codingPath: [CodingKey]
        ) -> Bool {
            guard !hiddenCodingPaths.isEmpty else {
                return false
            }
            
            let codingPathForKey = codingPath.map({ AnyCodingKey(erasing: $0) }).appending(AnyCodingKey(erasing: key))
            
            if hiddenCodingPaths.contains(codingPathForKey) {
                return true
            } else {
                return false
            }
        }
        
        func nested(forKey key: some CodingKey) -> Self {
            var result = self
            
            result.codingPath.append(AnyCodingKey(erasing: key))
            result.hiddenCodingPaths._forEach(mutating: {
                $0.removeFirst()
            })
            
            return result
        }
    }
    
    public struct Context {
        let type: Any.Type?
    }
}

extension Decoder {
    public func _determineContainerKind(
        guess: _DecodingContainerKind? = nil // TODO: Use this at some point
    ) throws -> _DecodingContainerKind {
        try _DecodingContainerKind.allCases.first(byUnwrapping: { kind in
            do {
                _ = try _container(ofKind: kind)
                
                return kind
            } catch {
                return nil
            }
        })
        .unwrap()
    }
}

extension Decoder {
    public func _hidingCodingKey(_ key: some CodingKey) -> Decoder {
        var result = _ModularDecoder(wrapping: self)
        
        result.hideCodingPath([key])
        
        return result
    }
}
