//
// Copyright (c) Vatsal Manot
//

import Foundation
@_spi(Internal) import _SwallowSwiftOverlay
@_spi(Internal) import Swallow

protocol _UnsafeSerializationRepresentable {
    associatedtype _UnsafeSerializationRepresentation: Codable & Hashable
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation { get throws }
    
    init(_unsafeSerializationRepresentation: _UnsafeSerializationRepresentation) throws
}

// MARK: - Extensions

extension _UnsafeSerializationRepresentable {
    static var _opaque_UnsafeSerializationRepresentation: Codable.Type {
        _UnsafeSerializationRepresentation.self
    }
    
    static func _opaque_decodeThroughUnsafeSerializationRepresentation(
        from decoder: Decoder
    ) throws -> Self {
        try Self(_unsafeSerializationRepresentation: try _UnsafeSerializationRepresentation(from: decoder))
    }
    
    static func _opaque_decodeUnsafeSerializationRepresentation(
        from decoder: Decoder
    ) throws -> _UnsafeSerializationRepresentation {
        try _UnsafeSerializationRepresentation(from: decoder)
    }
    
    init(_opaque_unsafeSerializationRepresentation x: Any) throws {
        try self.init(_unsafeSerializationRepresentation: try cast(x))
    }
}

// MARK: - Implemented Conformances

extension HeterogeneousDictionary: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = [_UnsafelySerializedKeyValuePair]
    
    public struct _UnsafelySerializedKeyValuePair: Hashable, Codable {
        public enum CodingKeys: String, CodingKey {
            case key
            case value
        }
        
        @_UnsafelySerialized
        public var key: any HeterogeneousDictionaryKey.Type
        @_UnsafelySerialized
        public var value: Any
        
        public init(
            key: any HeterogeneousDictionaryKey.Type,
            value: Any
        ) {
            self.key = key
            self.value = value
        }
        
        public init<T>(
            key: AnyHeterogeneousDictionaryKey,
            value: T
        ) throws {
            self.key = try cast(key.base)
            self.value = value
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self._key = try container.decode(forKey: .key)
            
            func decodeValue<Value>(_: Value.Type) throws -> Any {
                try _unwrapPossiblyOptionalAny(container.decode(_UnsafelySerialized<Value>.self, forKey: .value).wrappedValue)
            }
            
            self.value = try _openExistential(_key.wrappedValue._opaque_Value.self, do: decodeValue)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(_key, forKey: .key)
            try container.encode(_value, forKey: .value)
        }
    }
    
    var _unsafeSerializationRepresentation: [_UnsafelySerializedKeyValuePair] {
        get throws {
            try map {
                try _UnsafelySerializedKeyValuePair(key: $0.key, value: $0.value)
            }
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: [_UnsafelySerializedKeyValuePair]
    ) throws {
        self.init(_unsafeStorage: representation._mapToDictionary(
            key: {
                AnyHeterogeneousDictionaryKey(base: $0.key)
            },
            value: {
                $0.value
            }
        ))
    }
}

extension Array: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = [_TypeSerializingAnyCodable]
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try _TypeSerializingAnyCodable($0, declaredAs: Element.self) })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        self = try representation.lazy.map({ try $0.decode(Element.self) })
    }
}

extension _BagOfExistentials: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Array<_TypeSerializingAnyCodable>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try _TypeSerializingAnyCodable($0) })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        try self.init(representation.map({ try $0.decode(Element.self) }))
    }
}

public struct _DictionaryUnsafeSerializationRepresentation: Codable, Hashable {
    var storage: [_TypeSerializingAnyCodable: _TypeSerializingAnyCodable]
    
    init(storage: [_TypeSerializingAnyCodable: _TypeSerializingAnyCodable]) {
        self.storage = storage
    }
    
    public init(from decoder: any Decoder) throws {
        do {
            let storage: [_TypeSerializingAnyCodable: _TypeSerializingAnyCodable]
            
            do {
                storage = try [_TypeSerializingAnyCodable: _TypeSerializingAnyCodable](from: decoder)
            } catch {
                do {
                    storage = try [AnyCodingKey: _TypeSerializingAnyCodable](from: decoder).mapKeys { key in
                        return _TypeSerializingAnyCodable(_data: key.stringValue)
                    }
                } catch {
                    storage = try [AnyCodingKey: _TypeSerializingAnyCodable](from: AnyCodable(from: decoder)).mapKeys { key in
                        return _TypeSerializingAnyCodable(_data: key.stringValue)
                    }
                }
            }
            
            self.storage = storage
        } catch {
            throw error
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        try storage.encode(to: encoder)
    }
}

extension Dictionary: _UnsafeSerializationRepresentable {
    public typealias _UnsafeSerializationRepresentation = _DictionaryUnsafeSerializationRepresentation
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            _UnsafeSerializationRepresentation(
                storage: try mapKeysAndValues(
                    { try _TypeSerializingAnyCodable($0) },
                    { try _TypeSerializingAnyCodable($0) }
                )
            )
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        self = try representation.storage.mapDictionary(
            key: { key -> Key in
                return try key.decode(Key.self)
            },
            value: { value -> Value in
                return try value.decode(Value.self)
            }
        )
    }
}

extension _ExistentialSet: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Set<_TypeSerializingAnyCodable>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try Set(lazy.map({ try _TypeSerializingAnyCodable($0) }))
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        try self.init(representation.map({ try $0.decode(Element.self) }))
    }
}

extension _HashableExistentialArray: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Array<_TypeSerializingAnyCodable>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try _TypeSerializingAnyCodable($0) })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        try self.init(representation.map({ try $0.decode(Element.self) }))
    }
}

extension IdentifierIndexingArray: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Array<_TypeSerializingAnyCodable>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try _TypeSerializingAnyCodable($0) })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        if let type = Self.self as? any _UnsafelySerializationRepresentableIdentifierIndexingArray.Type {
            self = try cast(type.init(_unsafeSerializationRepresentation: representation))
        } else if let elementType = Element.self as? any Identifiable.Type, ID.self == elementType._opaque_ID.self {
            self = try elementType._decodeIdentifierIndexingArray(Self.self, from: representation)
        } else {
            throw Never.Reason.unavailable
        }
    }
}

extension Identifiable {
    fileprivate static var _opaque_ID: Any.Type {
        ID.self
    }
    
    fileprivate static func _decodeIdentifierIndexingArray<T, U>(
        _ type: IdentifierIndexingArray<T, U>.Type,
        from representation: Array<_TypeSerializingAnyCodable>
    ) throws -> IdentifierIndexingArray<T, U> {
        assert(T.self == Self.self)
        assert(U.self == Self.ID.self)
        
        return try IdentifierIndexingArray<T, U>(
            representation.map({ try unsafeBitCast($0.decode(Self.self), to: T.self) }),
            id: { unsafeBitCast(unsafeBitCast($0, to: Self.self).id, to: U.self) }
        )
    }
}

protocol _UnsafelySerializationRepresentableIdentifierIndexingArray: IdentifierIndexingArrayType where ID == AnyHashable {
    var _unsafeSerializationRepresentation: Array<_TypeSerializingAnyCodable> { get throws }
    
    init(_unsafeSerializationRepresentation _: Array<_TypeSerializingAnyCodable>) throws
}

extension IdentifierIndexingArray: _UnsafelySerializationRepresentableIdentifierIndexingArray where ID == AnyHashable {
    var _unsafeSerializationRepresentation: Array<_TypeSerializingAnyCodable> {
        get throws {
            try Array(self)._unsafeSerializationRepresentation
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: Array<_TypeSerializingAnyCodable>
    ) throws {
        let array = try Array<Element>(_unsafeSerializationRepresentation: representation)
        
        self.init(array, id: { ($0 as! any Identifiable).id.erasedAsAnyHashable })
    }
}

extension Optional: _UnsafeSerializationRepresentable where Wrapped: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Optional<Wrapped._UnsafeSerializationRepresentation>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try $0._unsafeSerializationRepresentation })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        self = try representation.map({ try Wrapped(_unsafeSerializationRepresentation: $0) })
    }
}

extension Result: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Result<_TypeSerializingAnyCodable, Erroneous<_TypeSerializingAnyCodable>>._CodableRepresentation
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try .init(
                from: self
                    .mapSuccess({ try _TypeSerializingAnyCodable($0) })
                    .mapFailure({ try Erroneous(_TypeSerializingAnyCodable($0)) })
            )
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        self = try Result<_TypeSerializingAnyCodable, Erroneous<_TypeSerializingAnyCodable>>(representation)
            .mapSuccess({ try $0.decode(Success.self) })
            .mapFailure({ try $0.value.decode(Failure.self) })
    }
}

extension Set: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Set<_TypeSerializingAnyCodable>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try .init(lazy.map({ try _TypeSerializingAnyCodable($0) }))
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        try self.init(representation.lazy.map({ try $0.decode(Element.self) }))
    }
}
