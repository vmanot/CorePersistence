//
// Copyright (c) Vatsal Manot
//

import Swallow

//@RepresentationBuilder(for: )
public protocol CodingRepresentation<Item> {
    associatedtype Item: Codable
    associatedtype Body: CodingRepresentation
    
    var body: Body { get }
}

public protocol _CodingRepresentatable: Codable {
    associatedtype CodingRepresentationType: CodingRepresentation<Self>
    
    static var codingRepresentation: CodingRepresentationType { get }
}

extension CodingRepresentation {
    
}

/*@resultBuilder
public struct CodingRepresentationBuilder {
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
        .init(base: [representation])
    }
    
    public static func buildPartialBlock(
        first string: String
    ) -> Accumulated {
        .init(base: [_StringIdentityRepresentation(string)])
    }
    
    public static func buildPartialBlock<R: IdentityRepresentation>(
        accumulated: Accumulated,
        next: R
    ) -> Accumulated  {
        .init(base: accumulated.base + [next])
    }
}

extension CodingRepresentationBuilder {
    /// This type is a work-in-progress. Do not use this type directly in your code.
    public struct Accumulated: IdentityRepresentation {
        var base: [any IdentityRepresentation]
        
        public var body: some IdentityRepresentation {
            self
        }
    }
}*/

public struct _ResolvedCodingRepresentation {
    public enum Attribute {
        
    }
}
