//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow

public struct AnyCodingKeyAlias: Codable, Hashable, Sendable {
    public let source: AnyCodingKey
    public let destination: AnyCodingKey
    
    public init(source: AnyCodingKey, destination: AnyCodingKey) {
        self.source = source
        self.destination = destination
    }
    
    public func reversed() -> Self {
        Self(source: destination, destination: source)
    }
}
