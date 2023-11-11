//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Swallow

public struct HadeanTopLevelCoder<EncodedRepresentation> {    
    private let base: _ModularTopLevelCoder<EncodedRepresentation>
    
    private init(base: _ModularTopLevelCoder<EncodedRepresentation>) {
        _ = _UniversalTypeRegistry.shared
        
        var base = base
        
        base.plugins = [
            _DotNetTypeIdentifierCodingPlugin(
                idResolver: _UniversalTypeRegistry.typeToIdentifierResolver,
                typeResolver: _UniversalTypeRegistry.identifierToTypeResolver
            )
        ]
        
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
        self.init(base: .init(decoder: decoder, encoder: encoder))
    }
    
    public init<Coder: TopLevelDataCoder>(
        coder: Coder
    ) where EncodedRepresentation == Data {
        self.init(base: .init(coder: coder))
    }
}

// MARK: - Conformances

extension HadeanTopLevelCoder: TopLevelDataCoder where EncodedRepresentation == Data {
    
}
