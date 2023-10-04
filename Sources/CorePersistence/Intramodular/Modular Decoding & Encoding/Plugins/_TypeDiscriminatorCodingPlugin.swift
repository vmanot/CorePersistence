//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _TypeDiscriminatorCodingPlugin: _ModularCodingPlugin {
    associatedtype Discriminator: Hashable
    
    func resolveType(for discriminator: Discriminator) throws -> Any.Type?
    func resolveDiscriminator(for type: Any.Type) throws -> Discriminator?
    
    func decode(
        from _: Decoder,
        context: Context
    ) throws -> Discriminator?
    
    func encode(
        _ discriminator: Discriminator,
        to encoder: Encoder,
        context: Context
    ) throws
}

extension _TypeDiscriminatorCodingPlugin {
    func _opaque_encode(
        _ discriminator: Any,
        to encoder: Encoder,
        context: Context
    ) throws {
        try encode(
            cast(discriminator, to: Discriminator.self),
            to: encoder,
            context: context
        )
    }
}
