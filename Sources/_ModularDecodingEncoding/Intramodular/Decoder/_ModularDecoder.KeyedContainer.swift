//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _ModularDecoder {
    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        private var base: KeyedDecodingContainer<Key>
        private var parent: _ModularDecoder
        
        init(
            base: KeyedDecodingContainer<Key>,
            parent: _ModularDecoder
        ) {
            self.parent = parent
            self.base = base
        }
        
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
            
            do {
                return try base.decode(KeyedContainerProxyDecodable<T>.self, forKey: key).value
            } catch let error as _ModularDecodingError {
                switch error {
                    case .typeMismatch:
                        throw error
                    case .keyNotFound:
                        return try attemptToRecover(
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
                        return try attemptToRecover(
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
        
        /// Attempts to recover from a `.keyNotFound` error.
        ///
        /// Only proceeds if a recovery plugin is explicitly specified, the default behavior of `Codable` is to throw an error for a missing key.
        private func attemptToRecover<T>(
            fromKeyNotFoundError error: Error,
            type: T.Type,
            key: Key
        ) throws -> T {
            guard let error = _ModularDecodingError(error) else {
                throw error
            }
            
            let errorCodingPath: [AnyCodingKey] = try error.context?.codingPath.map({ try $0.key.unwrap() }) ?? []
            
            guard errorCodingPath == self.codingPath.map({ AnyCodingKey(erasing: $0) }) else {
                throw error
            }
            
            guard self.parent.configuration.plugins.contains(where: { $0 is _KeyNotFoundRecoveryPlugin }) else {
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
        
        func decodeIfPresent<T: Decodable>(
            _ type: T.Type,
            forKey key: Key
        ) throws -> T? {
            if parent.configuration.hides(key, at: base.codingPath) {
                return nil
            }
            
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
            
            return try base.decodeIfPresent(KeyedContainerProxyDecodable<T>.self, forKey: key)?.value
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy type: NestedKey.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<NestedKey>  {
            .init(
                KeyedContainer<NestedKey>(
                    base: try base.nestedContainer(keyedBy: type, forKey: key),
                    parent: parent
                )
            )
        }
        
        func nestedUnkeyedContainer(
            forKey key: Key
        ) throws -> UnkeyedDecodingContainer {
            UnkeyedContainer(
                base: try base.nestedUnkeyedContainer(forKey: key),
                parent: parent
            )
        }
        
        func superDecoder() throws -> Decoder {
            _ModularDecoder(
                base: try base.superDecoder(),
                configuration: parent.configuration,
                context: .init(type: nil)
            )
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            _ModularDecoder(
                base: try base.superDecoder(forKey: key),
                configuration: parent.configuration,
                context: .init(type: nil)
            )
        }
    }
}
