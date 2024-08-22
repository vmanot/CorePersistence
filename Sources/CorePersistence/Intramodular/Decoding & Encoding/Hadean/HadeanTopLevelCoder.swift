//
// Copyright (c) Vatsal Manot
//

import _ModularDecodingEncoding
import Combine
import FoundationX
import Runtime
import Swallow

public struct HadeanTopLevelCoder<EncodedRepresentation>: _ModularTopLevelCoder {
    private var base: _AnyModularTopLevelCoder<EncodedRepresentation>
    
    public var plugins: [any _ModularCodingPlugin] {
        get {
            base.plugins
        } set {
            base.plugins = newValue
        }
    }
    
    private init(
        base: _AnyModularTopLevelCoder<EncodedRepresentation>
    ) {
        assert(base.plugins.isEmpty)
        
        var base = base
        
        let newPlugins: [any _ModularCodingPlugin] =  [
            _HadeanTypeCodingPlugin(),
            _DotNetTypeIdentifierCodingPlugin(
                idResolver: _HadeanSwiftTypeRegistry.typeToIdentifierResolver,
                typeResolver: _HadeanSwiftTypeRegistry.identifierToTypeResolver
            )
        ]
        
        base.plugins.append(contentsOf: newPlugins)
        
        self.base = base
    }
    
    public func _eraseToAnyModularTopLevelCoder() -> _AnyModularTopLevelCoder<EncodedRepresentation> {
        base
    }
}

extension HadeanTopLevelCoder: TopLevelDecoder, TopLevelEncoder {
    public func decode<T>(
        _ type: T.Type = T.self,
        from data: EncodedRepresentation
    ) throws -> T {
        try base.decode(type, from: data)
    }
    
    public func encode<T>(_ value: T) throws -> EncodedRepresentation {
        try base.encode(value)
    }
}

// MARK: - Initializers

extension HadeanTopLevelCoder {
    public init<Decoder: TopLevelDecoder, Encoder: TopLevelEncoder>(
        decoder: Decoder,
        encoder: Encoder
    ) where Decoder.Input == EncodedRepresentation, Encoder.Output == EncodedRepresentation {
        self.init(base: _AnyModularTopLevelCoder(decoder: decoder, encoder: encoder))
    }
    
    public init<Coder: TopLevelDataCoder>(
        coder: Coder
    ) where EncodedRepresentation == Data {
        self.init(base: _AnyModularTopLevelCoder(coder: coder))
    }
    
    public init<Coder: TopLevelDataCoder>(
        coder: Coder,
        plugins: [any _ModularCodingPlugin]
    ) where EncodedRepresentation == Data {
        self.init(base: _AnyModularTopLevelCoder(coder: coder))
        
        self.base.plugins.append(contentsOf: plugins)
    }
}

// MARK: - Conformances

extension HadeanTopLevelCoder: TopLevelDataCoder where EncodedRepresentation == Data {
    public var userInfo: [CodingUserInfoKey: Any] {
        get {
            base.userInfo
        } set {
            base.userInfo = newValue
        }
    }
}

// MARK: - Auxiliary

public final class _HadeanTypeCodingPlugin: _MetatypeCodingPlugin {
    public typealias CodableRepresentation = HadeanIdentifier
    
    public init() {
        
    }
    
    public func codableRepresentation(
        for type: Any.Type,
        context: Context
    ) throws -> CodableRepresentation {
        try _HadeanSwiftTypeRegistry[type].unwrap()
    }
    
    public func type(
        from codableRepresentation: CodableRepresentation,
        context: Context
    ) throws -> Any.Type {
        try _HadeanSwiftTypeRegistry[codableRepresentation].unwrap()
    }
}
