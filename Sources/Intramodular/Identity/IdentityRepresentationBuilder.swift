//
// Copyright (c) Vatsal Manot
//

import Swallow

@resultBuilder
public struct IdentityRepresentationBuilder {
    public static func buildBlock<I: IdentityRepresentation>(_ representation: I) -> I {
        representation
    }
    
    static func buildPartialBlock<I: IdentityRepresentation>(first representation: I) -> AccumulatedIdentityRepresentations {
        .init(representations: [representation])
    }
    
    public static func buildPartialBlock<I: IdentityRepresentation>(
        accumulated: AccumulatedIdentityRepresentations, next: I
    ) -> AccumulatedIdentityRepresentations  {
        AccumulatedIdentityRepresentations(representations: accumulated.representations + [next])
    }
}

public struct AccumulatedIdentityRepresentations: IdentityRepresentation {
    let representations: [any IdentityRepresentation]
    
    public var body: some IdentityRepresentation {
        self
    }
}
