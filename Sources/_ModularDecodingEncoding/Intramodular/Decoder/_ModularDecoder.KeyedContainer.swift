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
        if decoder.configuration.hides(key, at: base.codingPath) {
            throw _ModularDecodingError.keyForbidden(
                AnyCodingKey(erasing: key),
                _ModularDecodingError.Context(type: type, codingPath: self.codingPath)
            )
        }

        return try _decodeRecoveringMissingKey(type, forKey: key) {
            try base._decodePrimitive(type, forKey: key)
        }
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

        return try _decodeRecoveringMissingKey(type, forKey: key) {
            if let result: T = try _primitiveDecode(type, forKey: key) {
                return result
            } else if T.self == _CodableSwiftType.self {
                return try base.decode(T.self, forKey: key)
            } else {
                return try base.decode(_ModularDecoder.KeyedContainerProxyDecodable<T>.self, forKey: key).value
            }
        }
    }
            
    func decodeIfPresent<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T? {
        if decoder.configuration.hides(key, at: base.codingPath) {
            return nil
        }

        if !base.contains(key) {
            let aliasedValue = try _decodeAliasedValueIfPresent(type, forKey: key)

            if aliasedValue.wasFound {
                return aliasedValue.value
            }
        }

        if let result: T = try _primitiveDecodeIfPresent(type, forKey: key) {
            return result
        } else if T.self == _CodableSwiftType.self {
            return try base.decodeIfPresent(T.self, forKey: key)
        } else {
            return try base.decodeIfPresent(_ModularDecoder.KeyedContainerProxyDecodable<T>.self, forKey: key)?.value
        }
    }

    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
        try _decodePrimitiveIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
        try _decodePrimitiveIfPresent(type, forKey: key)
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
        if _requiresDirectCodingWithUnderlyingCoder(type) {
            return try base.decode(T.self, forKey: key)
        }
        
        return nil
    }
    
    private func _primitiveDecodeIfPresent<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T? {
        if _requiresDirectCodingWithUnderlyingCoder(type) {
            return try base.decodeIfPresent(T.self, forKey: key)
        }
        
        return nil
    }

    private func _decodePrimitiveIfPresent<T: CoderPrimitive>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T? {
        if decoder.configuration.hides(key, at: base.codingPath) {
            return nil
        }

        if !base.contains(key) {
            let aliasedValue = try _decodeAliasedValueIfPresent(type, forKey: key)

            if aliasedValue.wasFound {
                return aliasedValue.value
            }
        }

        return try base.decodeIfPresent(type, forKey: key)
    }

    private func _decodeRecoveringMissingKey<T: Decodable>(
        _ type: T.Type,
        forKey key: Key,
        operation: () throws -> T
    ) throws -> T {
        do {
            return try operation()
        } catch let error as _ModularDecodingError {
            guard case .keyNotFound = error else {
                throw error
            }

            return try _attemptToRecover(
                fromKeyNotFoundError: error,
                type: type,
                key: key
            )
        } catch let error as DecodingError {
            guard case .keyNotFound = error else {
                throw error
            }

            return try _attemptToRecover(
                fromKeyNotFoundError: error,
                type: type,
                key: key
            )
        }
    }

    private func _codingKeyAliases(
        for key: Key
    ) -> [AnyCodingKey] {
        guard let subjectType = decoder.context.type as? any _CodingRepresentationProvider.Type else {
            return []
        }

        return _ResolvedCodingRepresentation
            ._for(subjectType)
            .keysToKeyAliases[AnyCodingKey(erasing: key), default: []]
            .map({ $0 })
    }

    private func _decodeAliasedValue<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T? {
        let aliases = _codingKeyAliases(for: key)

        guard !aliases.isEmpty else {
            return nil
        }

        let container = try decoder.base.container(keyedBy: AnyCodingKey.self)
        var firstAliasError: Error?

        for alias in aliases where container.contains(alias) {
            do {
                return try container.decode(type, forKey: alias)
            } catch {
                if firstAliasError == nil {
                    firstAliasError = error
                }
            }
        }

        if let firstAliasError {
            throw _ModularDecoder.NonRetryableDecodingError(
                underlyingError: firstAliasError
            )
        }

        return nil
    }

    private func _decodeAliasedValueIfPresent<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> (wasFound: Bool, value: T?) {
        let aliases = _codingKeyAliases(for: key)

        guard !aliases.isEmpty else {
            return (false, nil)
        }

        let container = try decoder.base.container(keyedBy: AnyCodingKey.self)
        var firstAliasError: Error?

        for alias in aliases where container.contains(alias) {
            do {
                return (true, try container.decodeIfPresent(type, forKey: alias))
            } catch {
                if firstAliasError == nil {
                    firstAliasError = error
                }
            }
        }

        if let firstAliasError {
            throw _ModularDecoder.NonRetryableDecodingError(
                underlyingError: firstAliasError
            )
        }

        return (false, nil)
    }
    
    /// Attempts to recover from a `.keyNotFound` error.
    ///
    /// Only proceeds if a recovery plugin is explicitly specified, the default behavior of `Codable` is to throw an error for a missing key.
    private func _attemptToRecover<T: Decodable>(
        fromKeyNotFoundError error: Error,
        type: T.Type,
        key: Key
    ) throws -> T {
        guard let error = _ModularDecodingError(error) else {
            throw error
        }

        guard case .keyNotFound(let missingKey, _, _) = error else {
            throw error
        }

        guard missingKey == AnyCodingKey(erasing: key) else {
            throw error
        }

        let errorCodingPath: [AnyCodingKey] = try error.context?.codingPath.map({ try $0.key.unwrap() }) ?? []

        guard errorCodingPath == self.codingPath.map({ AnyCodingKey(erasing: $0) }) else {
            throw error
        }

        if let result = try _decodeAliasedValue(type, forKey: key) {
            return result
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
