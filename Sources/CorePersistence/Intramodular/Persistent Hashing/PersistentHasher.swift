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

// MARK: - Conformees

extension _DJB2PersistentHasher: PersistentHasher {
    
}

/// A persistent hasher that reads the contents of files and hashes them.
public struct _SecureFileContentsHasher<Base: HashFunction>: PersistentHasher {
    private var base = Base()
    
    public init(base: Base) {
        self.base = base
    }
    
    public mutating func combine<H: Codable>(_ value: H) throws {
        let handle: FileHandle
        
        if let value = value as? URL {
            handle = try FileHandle(forReadingFrom: value)
        } else if let value = value as? FileHandle {
            handle = value
        } else {
            throw Error.unsupportedValue(ofType: type(of: value))
        }
        
        while autoreleasepool(invoking: {
            let nextChunk = handle.readData(ofLength: Base.blockByteCount)
            
            guard !nextChunk.isEmpty else {
                return false
            }
            
            base.update(data: nextChunk)
            
            return true
        }) { }
    }
    
    public init() {
        
    }
    
    public func finalize() throws -> Data {
        let digest = base.finalize()
        
        return Data(digest)
    }
    
    public enum Error: Swift.Error {
        case unsupportedValue(ofType: Any.Type)
    }
}

extension _SecureFileContentsHasher where Base == CryptoKit.SHA256 {
    public static var SHA256: Self {
        Self(base: CryptoKit.SHA256())
    }
}

public struct _JSONPersistentHasher: PersistentHasher {
    public typealias HashType = String
    
    private struct State: Encodable, @unchecked Sendable {
        public var data: [AnyCodable] = []
    }
    
    private var encoder: JSONEncoder = {
        let result = JSONEncoder()
        
        result.outputFormatting = [.sortedKeys]
        
        return result
    }()
    private var state = State()
    
    public init() {
        
    }
    
    public mutating func combine<H: Codable>(_ value: H) throws {
        state.data.append(AnyCodable(value))
    }
    
    public func finalize() throws -> String {
        let data: Data = try encoder.encode(state)
        let sha256 = SHA256.hash(data: data)
        
        return sha256.hexadecimalString
    }
}

// MARK: - Supplementary

extension ProcessInfo.Fingerprint: _CoreIdentity.PersistentIdentifierConvertible {
    public typealias PersistentID = String
    
    public var persistentID: PersistentID {
        try! _JSONPersistentHasher.hash(self)
    }
}
