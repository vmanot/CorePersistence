//
// Copyright (c) Vatsal Manot
//

@_spi(Internal) import Swallow

public struct _UniversalTypeRegistry {
    static let lock = OSUnfairLock()
    
    public static let shared = _UniversalTypeRegistry()
    
    @usableFromInline
    static var typesByIdentifier: [HadeanIdentifier: Any.Type] = [:]
    @usableFromInline
    static var identifiersByType: [Metatype<Any.Type>: HadeanIdentifier] = [:]
    
    static let identifierToTypeResolver = IdentifierToSwiftTypeResolver()
    static let typeToIdentifierResolver = SwiftTypeToIdentifierResolver()
    
    private init() {
        
    }
    
    public static func register(_ type: Any.Type) {
        lock.withCriticalScope {
            _register(type)
        }
    }
    
    @usableFromInline
    static func _register(_ type: Any.Type) {
        if let type = type as? (any HadeanIdentifiable.Type) {
            let identifier = type.hadeanIdentifier
            
            if let existing = typesByIdentifier[identifier] {
                assert(existing == type)
            } else {
                typesByIdentifier[type.hadeanIdentifier] = type
                identifiersByType[Metatype(type)] = identifier
            }
        }
        
        if let namespaceType = type as? (any _TypeIterableStaticNamespaceType.Type) {
            namespaceType._opaque_allNamespaceTypes.forEach(_register)
        }
    }
    
    public static func register(
        _ type: Any.Type,
        forIdentifier identifier: HadeanIdentifier
    ) {
        lock.withCriticalScope {
            assert(!(type is any HadeanIdentifiable.Type))
            assert(!(type is any _TypeIterableStaticNamespaceType.Type))
            
            typesByIdentifier[identifier] = type
            identifiersByType[Metatype(type)] = identifier
        }
    }
    
    public static subscript(
        _ type: Any.Type
    ) -> HadeanIdentifier? {
        get throws {
            try typeToIdentifierResolver.resolve(from: .init(type))
        }
    }
    
    public static subscript(
        _ type: HadeanIdentifier
    ) -> Any.Type? {
        get throws {
            try identifierToTypeResolver.resolve(from: type)?.value
        }
    }
}

// MARK: - Conformances

extension _UniversalTypeRegistry: Sequence {
    public func makeIterator() -> AnyIterator<Metatype<Any.Type>> {
        .init(Self.identifiersByType.keys.makeIterator())
    }
}

// MARK: - Auxiliary

extension _UniversalTypeRegistry {
    public enum _Error: Error {
        case failedToResolveIdentifier(for: Any.Type)
    }
    
    @usableFromInline
    struct IdentifierToSwiftTypeResolver: _PersistentIdentifierToSwiftTypeResolver {
        @usableFromInline
        typealias Input = HadeanIdentifier
        @usableFromInline
        typealias Output = _ExistentialSwiftType<Any, Any.Type>
        
        fileprivate init() {
            
        }
        
        @usableFromInline
        func resolve(
            from input: Input
        ) throws -> Output? {
            typesByIdentifier[input].map({ .existential($0) })
        }
    }
    
    @frozen
    @usableFromInline
    struct SwiftTypeToIdentifierResolver: _StaticSwiftTypeToPersistentIdentifierResolver {
        @usableFromInline
        typealias Input = _ExistentialSwiftType<Any, Any.Type>
        @usableFromInline
        typealias Output = HadeanIdentifier
        
        fileprivate init() {
            
        }
        
        @usableFromInline
        func resolve(
            from input: Input
        ) throws -> Output? {
            let type = input.value
            
            guard let identifier = identifiersByType[Metatype(type)] else {
                if (type is any HadeanIdentifiable.Type) {
                    throw _Error.failedToResolveIdentifier(for: input.value)
                } else {
                    return nil
                }
            }
            
            return identifier
        }
    }
}
