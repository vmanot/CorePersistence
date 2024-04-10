//
// Copyright (c) Vatsal Manot
//

import CryptoKit
import Foundation

public protocol PersistentHasher {
    associatedtype HashType: Codable & Hashable
    
    mutating func combine<H: Codable>(_ value: H) throws
    
    init()
    
    func finalize() throws -> HashType
}

public struct _JSONPersistentHasher: PersistentHasher {
    public typealias HashType = String
    
    private struct State: Encodable, @unchecked Sendable {
        public var data: [AnyCodable] = []
    }
    
    private var state = State()
    
    public init() {
        
    }
    
    public mutating func combine<H: Codable>(_ value: H) throws {
        state.data.append(AnyCodable(value))
    }
    
    public func finalize() throws -> String {
        let data: Data = try JSONEncoder().encode(state)
        let sha256 = SHA256.hash(data: data)
        
        return sha256.hexadecimalString
    }
}
