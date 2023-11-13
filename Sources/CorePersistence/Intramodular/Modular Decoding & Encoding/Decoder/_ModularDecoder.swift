//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

struct _ModularDecoder: Decoder {
    struct Configuration {
        var plugins: [any _ModularCodingPlugin] = []
        
        var allowsUnsafeSerialization: Bool {
            plugins.contains(where: { $0 is _UnsafeSerializationPlugin })
        }
    }
    
    struct Context {
        let type: Any.Type?
    }
    
    let base: Decoder
    let configuration: Configuration
    let context: Context
    
    var codingPath: [CodingKey] {
        base.codingPath
    }
    
    var userInfo: [CodingUserInfoKey: Any] {
        base.userInfo
    }
    
    init(
        base: Decoder,
        configuration: Configuration,
        context: Context
    ) {
        self.base = base
        self.configuration = configuration
        self.context = context
    }
    
    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        .init(
            KeyedContainer(
                base: try base.container(keyedBy: type),
                parent: self
            )
        )
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        UnkeyedContainer(
            base: try base.unkeyedContainer(),
            parent: self
        )
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(
            try base.singleValueContainer(),
            parent: self
        )
    }
}

// MARK: - Error Handling

public enum _ModularDecodingError: Error {
    public struct Context: Sendable {
        let type: Decodable.Type? // FIXME?
        let codingPath: [CodingKey]
        let debugDescription: String
        let underlyingError: (any Error)?
        
        init(
            type: Decodable.Type?,
            codingPath: [CodingKey],
            debugDescription: String,
            underlyingError: (any Error)?
        ) {
            self.type = type
            self.codingPath = codingPath
            self.debugDescription = debugDescription
            self.underlyingError = underlyingError
        }
    }
    
    case unsafeSerializationUnsupported(Any.Type)
    case typeMismatch(Any.Type, Context, AnyCodable?)
    case valueNotFound(Any.Type, Context, AnyCodable?)
    case keyNotFound(CodingKey, Context, AnyCodable?)
    case dataCorrupted(Context, AnyCodable?)
    
    case unknown(Swift.DecodingError)
    
    init(
        from decodingError: Swift.DecodingError,
        type: (any Decodable.Type)?,
        value: AnyCodable?
    ) {
        guard let _context = decodingError.context else {
            self = .unknown(decodingError)
            
            return
        }
        
        let context = Self.Context(
            type: type,
            codingPath: _context.codingPath,
            debugDescription: _context.debugDescription,
            underlyingError: _context.underlyingError
        )
        
        switch decodingError {
            case .typeMismatch(let type, _):
                self = .typeMismatch(type, context, value)
            case .valueNotFound(let type, _):
                self = .valueNotFound(type, context, value)
            case .keyNotFound(let codingKey, _):
                self = .keyNotFound(codingKey, context, value)
            case .dataCorrupted(_):
                self = .dataCorrupted(context, value)
            @unknown default:
                self = .unknown(decodingError)
        }
    }
    
    public init?(_ error: any Error) {
        if let error = error as? Swift.DecodingError {
            self.init(from: error, type: nil, value: nil)
        } else {
            return nil
        }
    }
}

// MARK: - Auxiliary

extension Decoder {
    public func _determineContainerKind(
        guess: _DecodingContainerKind? = nil // TODO: Use this at some point
    ) throws -> _DecodingContainerKind {
        try _DecodingContainerKind.allCases.first(byUnwrapping: { kind in
            do {
                _ = try _container(ofKind: kind)
                
                return kind
            } catch {
                guard case .typeMismatch = _ModularDecodingError(error) else {
                    throw error
                }
                
                return nil
            }
        })
        .unwrap()
    }
}
