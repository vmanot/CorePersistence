//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _RawUserInfoProtocol: Codable, Hashable, Initiable, Sendable {
    
}

public enum _RawUserInfoKey: Codable, Hashable, @unchecked Sendable {
    case type(_SerializedTypeIdentity)
    case key(_SerializedTypeIdentity)
}

public struct _RawUserInfo: _RawUserInfoProtocol {
    private var storage: [_UnsafelySerialized<_RawUserInfoKey>: _UnsafelySerialized<Any>] = [:]
    
    public init() {
        
    }
    
    public subscript<Value: Hashable>(
        _ type: Value.Type
    ) -> Value? {
        get {
            let key = _key(fromType: type)
            
            return try! storage[key].map({ try cast($0.wrappedValue, to: Value.self) })
        } set {
            let key = _key(fromType: type)
            
            if let newValue {
                storage[key] = _UnsafelySerialized(wrappedValue: newValue)
            } else {
                storage[key] = nil
            }
        }
    }
    
    public mutating func assign<Value: Hashable>(
        _ value: Value
    ) {
        let key = _key(fromType: Swift.type(of: value))
        
        storage[key] = _UnsafelySerialized(wrappedValue: value)
    }
    
    private func _key<Value: Hashable>(
        fromType type: Value.Type
    ) -> _UnsafelySerialized<_RawUserInfoKey> {
        _UnsafelySerialized<_RawUserInfoKey>(.type(_SerializedTypeIdentity(from: type)))
    }
}

// MARK: - Conformances

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension _RawUserInfo: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        
    }
}

