//
// Copyright (c) Vatsal Manot
//

import _ModularDecodingEncoding
import Combine
import Swallow

public struct UserInfo: Hashable, Sendable {
    package let scope: Scope?
    package var storage = _RawUserInfo()
    
    public init(scope: Any.Type) {
        self.scope = .init(_swiftType: scope)
    }
    
    public init(unscoped: Void) {
        self.scope = nil
    }
}

// MARK: - Auxiliary

public protocol UserInfoKey<Domain> {
    associatedtype Domain
    associatedtype Value
    
    static var defaultValue: Value { get }
}

extension UserInfoKey where Value: OptionalProtocol {
    public static var defaultValue: Value {
        Value(nilLiteral: ())
    }
}

extension UserInfo {
    public struct Scope: Hashable, Sendable {
        @_HashableExistential
        public var _swiftType: Any.Type
        
        public init(_swiftType: Any.Type) {
            self._swiftType = _swiftType
        }
    }
}
