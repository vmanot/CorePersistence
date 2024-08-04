//
// Copyright (c) Vatsal Manot
//

import _CoreIdentity
import CryptoKit
import Foundation
import _SwallowSwiftOverlay
import Swallow

public protocol PersistentHasher {
    associatedtype HashType: Codable & Hashable
    
    mutating func combine<H: Codable>(_ value: H) throws
    
    init()
    
    func finalize() throws -> HashType
}

extension PersistentHasher {
    public static func hash(_ x: some Codable) throws -> HashType {
        var hasher = Self()
        
        try hasher.combine(x)
        
        return try hasher.finalize()
    }
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

// MARK: - Supplementary

extension ProcessInfo.Fingerprint: _CoreIdentity.PersistentIdentifierConvertible {
    public var persistentID: String {
        try! _JSONPersistentHasher.hash(self)
    }
}
