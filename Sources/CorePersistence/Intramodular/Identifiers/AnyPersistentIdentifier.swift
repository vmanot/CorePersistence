//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct AnyPersistentIdentifier: Codable, Hashable, Sendable {
    public typealias RawValue = any Codable & Hashable & Sendable
    
    @_UnsafelySerialized
    public var rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}
