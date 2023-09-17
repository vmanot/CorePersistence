//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import TabularData

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public final class TabularDataDecoder: TopLevelDecoder {
    public typealias Input = DataFrame
    
    public init() {
        
    }
    
    public func decode<T: Decodable>(
        _ type: T.Type,
        from input: Input
    ) throws -> T {
        let decoder = _TabularDataDecoder(
            owner: .topLevel,
            dataFrame: input
        )
        
        return try T(from: decoder)
    }
}
