//
// Copyright (c) Vatsal Manot
//

import _ModularDecodingEncoding
import Combine
import Swallow

public protocol _HasUserInfo {
    var userInfo: UserInfo { get }
}

public struct UserInfo: HeterogeneousDictionaryProtocol, Hashable, Sendable {
    public typealias _HeterogenousDictionaryKeyType = _TopLevelUserInfoKey

    package let _explicitlyAssignedScope: Scope?
    package var storage = _RawUserInfo()
    package var children: [Scope: UserInfo] = [:]
    
    package init(_scope scope: Scope) {
        self._explicitlyAssignedScope = scope
    }

    public init(_unscoped: Void) {
        self._explicitlyAssignedScope = nil
    }
        
    package subscript(_scope scope: Scope) -> UserInfo {
        get {
            children[scope, default: .init(_scope: scope)]
        } set {
            children[scope, default: .init(_scope: scope)] = newValue
        }
    }
    
    public subscript<Key: _TopLevelUserInfoKey>(_ key: Key.Type) -> Key.Value {
        get {
            storage[key]
        } set {
            storage[key] = newValue
        }
    }
}

// MARK: - Conformances

extension UserInfo: Codable {
    
}

extension UserInfo: CustomStringConvertible {
    public var description: String {
        "\(storage)"
    }
}

extension UserInfo: ThrowingMergeOperatable {
    public func mergeInPlace(with other: UserInfo) throws {
        
    }
}

// MARK: - Auxiliary

extension UserInfoKey where Value: OptionalProtocol {
    public static var defaultValue: Value {
        Value(nilLiteral: ())
    }
}
