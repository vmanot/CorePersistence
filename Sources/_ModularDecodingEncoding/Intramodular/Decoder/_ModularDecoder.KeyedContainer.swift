//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _ModularDecoder {
    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        private var base: KeyedDecodingContainer<Key>
        private var decoder: _ModularDecoder
        
        init(
            base: KeyedDecodingContainer<Key>,
            decoder: _ModularDecoder
        ) {
            self.decoder = decoder
            self.base = base
        }
    }
}

extension _ModularDecoder.KeyedContainer {
    var codingPath: [CodingKey] {
        base.codingPath
    }
    
    var allKeys: [Key] {
        base.allKeys
    }
    
    func contains(_ key: Key) -> Bool {
        base.contains(key)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        try base.decodeNil(forKey: key)
    }
    
    func decode<T: CoderPrimitive>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T {
        try base._decodePrimitive(type, forKey: key)
    }
    
    func decode<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T {
        if decoder.configuration.hides(key, at: base.codingPath) {
            throw _ModularDecodingError.keyForbidden(
                AnyCodingKey(erasing: key),
                _ModularDecodingError.Context(type: type, codingPath: self.codingPath)
            )
        }

        do {
            if let result: T = try _primitiveDecode(type, forKey: key) {
                return result
            } else if T.self == _CodableSwiftType.self {
                return try base.decode(T.self, forKey: key)
            } else {
                return try base.decode(_ModularDecoder.KeyedContainerProxyDecodable<T>.self, forKey: key).value
            }
        } catch let error as _ModularDecodingError {
            switch error {
                case .typeMismatch:
                    throw error
                case .keyNotFound:
                    return try _attemptToRecover(
                        fromKeyNotFoundError: error,
                        type: type,
                        key: key
                    )
                default:
                    throw error
            }
        } catch let error as DecodingError {
            switch error {
                case .typeMismatch:
                    fallthrough
                case .keyNotFound:
                    return try _attemptToRecover(
                        fromKeyNotFoundError: error,
                        type: type,
                        key: key
                    )
                default:
                    break
            }
            
            throw error
        }
    }
            
    func decodeIfPresent<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T? {
        if decoder.configuration.hides(key, at: base.codingPath) {
            return nil
        }

        if let result: T = try _primitiveDecodeIfPresent(type, forKey: key) {
            return result
        } else if T.self == _CodableSwiftType.self {
            return try base.decodeIfPresent(T.self, forKey: key)
        } else {
            return try base.decodeIfPresent(_ModularDecoder.KeyedContainerProxyDecodable<T>.self, forKey: key)?.value
        }
    }
    
    func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey>  {
        KeyedDecodingContainer(
            _ModularDecoder.KeyedContainer<NestedKey>(
                base: try base.nestedContainer(keyedBy: type, forKey: key),
                decoder: decoder
            )
        )
    }
    
    func nestedUnkeyedContainer(
        forKey key: Key
    ) throws -> UnkeyedDecodingContainer {
        _ModularDecoder.UnkeyedContainer(
            base: try base.nestedUnkeyedContainer(forKey: key),
            decoder: decoder
        )
    }
    
    func superDecoder() throws -> Decoder {
        _ModularDecoder(
            base: try base.superDecoder(),
            configuration: decoder.configuration,
            context: .init(type: nil)
        )
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        _ModularDecoder(
            base: try base.superDecoder(forKey: key),
            configuration: decoder.configuration,
            context: .init(type: nil)
        )
    }
    
    private func _primitiveDecode<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T? {
        guard !(type is Date.Type) else {
            return try base.decode(T.self, forKey: key)
        }
        
        guard !(type is Optional<Date>.Type) else {
            return try base.decode(T.self, forKey: key)
        }
        
        guard !(type is URL.Type) else {
            return try base.decode(T.self, forKey: key)
        }
        
        guard !(type is Optional<URL>.Type) else {
            return try base.decode(T.self, forKey: key)
        }
        
        return nil
    }
    
    private func _primitiveDecodeIfPresent<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T? {
        guard !(type is Date.Type) else {
            return try base.decodeIfPresent(T.self, forKey: key)
        }
        
        guard !(type is Optional<Date>.Type) else {
            return try base.decodeIfPresent(T.self, forKey: key)
        }
        
        guard !(type is URL.Type) else {
            return try base.decodeIfPresent(T.self, forKey: key)
        }
        
        guard !(type is Optional<URL>.Type) else {
            return try base.decodeIfPresent(T.self, forKey: key)
        }
        
        return nil
    }
    
    /// Attempts to recover from a `.keyNotFound` error.
    ///
    /// Only proceeds if a recovery plugin is explicitly specified, the default behavior of `Codable` is to throw an error for a missing key.
    private func _attemptToRecover<T>(
        fromKeyNotFoundError error: Error,
        type: T.Type,
        key: Key
    ) throws -> T {
        if let subjectType = decoder.context.type as? any _CodingRepresentationProvider.Type, let type = type as? Decodable.Type {
            let codingRepresentation = _ResolvedCodingRepresentation._for(subjectType)
            
            let result = codingRepresentation.keysToKeyAliases[AnyCodingKey(erasing: key), default: []].first(byUnwrapping: {
                return try? decoder.base.decode(type, forKey: $0)
            })
            
            if let result {
                return try cast(result)
            }
        }
        
        guard let error = _ModularDecodingError(error) else {
            throw error
        }
        
        let errorCodingPath: [AnyCodingKey] = try error.context?.codingPath.map({ try $0.key.unwrap() }) ?? []
        
        guard errorCodingPath == self.codingPath.map({ AnyCodingKey(erasing: $0) }) else {
            throw error
        }
        
        guard self.decoder.configuration.plugins.contains(where: { $0 is _KeyNotFoundRecoveryPlugin }) else {
            throw error
        }
        
        if let nilLiteral = try? _initializeNilLiteral(ofType: T.self) {
            return nilLiteral
        } else if let arrayLiteral = try? _initializeEmptyArrayLiteral(ofType: T.self) {
            return arrayLiteral
        } else if let initiable = try? cast(type, to: (any Initiable.Type).self) {
            return initiable.init() as! T
        } else {
            runtimeIssue("Failed to reasonably initialize \(type), trying all possible fallbacks including placeholder values.")
            
            return try _generatePlaceholder(ofType: type)
        }
    }
}
