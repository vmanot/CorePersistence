//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Runtime
import Swallow

public struct HadeanTopLevelCoder<EncodedRepresentation> {
    private var base: _ModularTopLevelCoder<EncodedRepresentation>
    
    private let plugins: [any _ModularCodingPlugin] = [
        _HadeanTypeCodingPlugin(),
        _DotNetTypeIdentifierCodingPlugin(
            idResolver: _HadeanSwiftTypeRegistry.typeToIdentifierResolver,
            typeResolver: _HadeanSwiftTypeRegistry.identifierToTypeResolver
        )
    ]
    
    private init(
        base: _ModularTopLevelCoder<EncodedRepresentation>
    ) {
        assert(base.plugins.isEmpty)
        
        var base = base
        
        base.plugins = plugins
        
        self.base = base
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
        self.init(base: _ModularTopLevelCoder(decoder: decoder, encoder: encoder))
    }
    
    public init<Coder: TopLevelDataCoder>(
        coder: Coder
    ) where EncodedRepresentation == Data {
        self.init(base: _ModularTopLevelCoder(coder: coder))
    }
    
    public init<Coder: TopLevelDataCoder>(
        coder: Coder,
        plugins: [any _ModularCodingPlugin]
    ) where EncodedRepresentation == Data {
        self.init(base: _ModularTopLevelCoder(coder: coder))
        
        self.base.plugins.append(contentsOf: plugins)
    }
}

// MARK: - Conformances

extension HadeanTopLevelCoder: TopLevelDataCoder where EncodedRepresentation == Data {
    
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
