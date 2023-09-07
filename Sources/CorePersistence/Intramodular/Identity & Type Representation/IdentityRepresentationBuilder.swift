//
// Copyright (c) Vatsal Manot
//

import Swallow

@resultBuilder
public struct IdentityRepresentationBuilder {
    public typealias Accumulated = _AccumulatedIdentityRepresentations
    
    public static func buildBlock<R: IdentityRepresentation>(
        _ representation: R
    ) -> R {
        representation
    }
    
    public static func buildBlock(
        _ string: String
    ) -> _StringIdentityRepresentation {
        .init(string)
    }
    
    public static func buildPartialBlock<R: IdentityRepresentation>(
        first representation: R
    ) -> Accumulated {
        .init(representations: [representation])
    }
    
    public static func buildPartialBlock(
        first string: String
    ) -> Accumulated {
        .init(representations: [_StringIdentityRepresentation(string)])
    }
    
    public static func buildPartialBlock<R: IdentityRepresentation>(
        accumulated: Accumulated,
        next: R
    ) -> Accumulated  {
        .init(representations: accumulated.representations + [next])
    }
}

/// This type is a work-in-progress. Do not use this type directly in your code.
public struct _AccumulatedIdentityRepresentations: IdentityRepresentation {
    let representations: [any IdentityRepresentation]
    
    public var body: some IdentityRepresentation {
        self
    }
}
