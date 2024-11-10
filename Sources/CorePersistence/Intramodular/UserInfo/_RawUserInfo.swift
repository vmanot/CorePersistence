//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _RawUserInfoProtocol: Codable, Hashable, Initiable, Sendable {
    
}

public struct _RawUserInfo: _RawUserInfoProtocol, Initiable, @unchecked Sendable {
    private var storage: [_RawUserInfoKey: _TypeSerializingAnyCodable] = [:]
    
    public var isEmpty: Bool {
        storage.isEmpty
    }
    
    public init() {
        
    }
        
    public mutating func assign<Value: Codable & Hashable>(
        _ value: Value
    ) {
        let key = _key(fromType: Swift.type(of: value))
        
        storage[key] = _TypeSerializingAnyCodable(value)
    }
    
    private func _key<Key: UserInfoKey>(
        fromKeyType type: Key.Type
    ) -> _RawUserInfoKey{
        _RawUserInfoKey.key(_CodableSwiftType(from: type))
    }
    
    private func _key<Value: Hashable>(
        fromType type: Value.Type
    ) -> _RawUserInfoKey {
        _RawUserInfoKey.type(_CodableSwiftType(from: type))
    }
    
    public subscript<T>(
        _key key: _RawUserInfoKey,
        as type: T.Type
    ) -> T? {
        get {
            return try! storage[key].map({ try cast($0.decode(T.self)) })
        } set {
            do {
                storage[key] = try _TypeSerializingAnyCodable(newValue)
            } catch {
                assertionFailure(error)
            }
        }
    }

    public subscript<Key: UserInfoKey>(
        _ type: Key.Type
    ) -> Key.Value {
        get {
            let key = _key(fromKeyType: type)
            
            return try! storage[key].map({ try cast($0.decode(Key.Value.self)) }) ?? Key.defaultValue
        } set {
            do {
                let key = _key(fromKeyType: type)
                
                storage[key] = try _TypeSerializingAnyCodable(newValue)
            } catch {
                assertionFailure(error)
            }
        }
    }
    
    public subscript<Value: Hashable>(
        _ type: Value.Type
    ) -> Value? {
        get {
            let key = _key(fromType: type)
            
            return try! storage[key].map({ try cast($0, to: Value.self) })
        } set {
            do {
                let key = _key(fromType: type)
                
                if let newValue {
                    storage[key] = try _TypeSerializingAnyCodable(newValue)
                } else {
                    storage[key] = nil
                }
            } catch {
                assertionFailure(error)
            }
        }
    }
}

// MARK: - Conformances

extension _RawUserInfo: CustomStringConvertible {
    public var description: String {
        storage.compactMapValues({ $0.data }).description
    }
}

extension _RawUserInfo: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.isEmpty && rhs.isEmpty {
            return true
        }
        
        guard lhs.storage.keys == rhs.storage.keys else {
            return false
        }
        
        for key in lhs.storage.keys {
            let lhsValue = lhs.storage[key]!
            
            guard let rhsValue = rhs.storage[key] else {
                return false
            }
            
            let isEqual: Bool? = #try(.optimistic) {
                guard try AnyEquatable(from: lhsValue) == AnyEquatable(from: rhsValue) else {
                    return false
                }
                
                return true
            }
            
            guard let _isEqual: Bool = isEqual, _isEqual else {
                return false
            }
        }
        
        return true
    }
}

extension _RawUserInfo: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        
    }
}

extension _RawUserInfo: Hashable {
    public func hash(into hasher: inout Hasher) {
        for (key, value) in storage {
            hasher.combine(key)
            hasher.combine(value)
        }
    }
}

extension _RawUserInfo: ThrowingMergeOperatable {
    public mutating func mergeInPlace(with other: _RawUserInfo) throws {
        var mergedKeys: Set<_RawUserInfoKey> = []
        
        for (key, value) in storage {
            if let otherValue = other.storage[key], var value = value as? (any ThrowingMergeOperatable) {
                try value._opaque_mergeInPlace(with: otherValue)
                
                self.storage[key] = try _TypeSerializingAnyCodable(value)
            }
        }
        
        for newKey in Set(other.storage.keys).subtracting(mergedKeys) {
            mergedKeys.insert(newKey)
        }
    }
}

// MARK: - Auxiliary

public enum _RawUserInfoKey: Codable, CustomStringConvertible, Hashable, @unchecked Sendable {
    case type(_CodableSwiftType)
    case key(_CodableSwiftType)
    
    public var description: String {
        switch self {
            case .type(let type):
                return "\(try! type.resolveType())"
            case .key(let type):
                return "\(try! type.resolveType())"
        }
    }
}
