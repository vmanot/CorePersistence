//
// Copyright (c) Vatsal Manot
//

import Swallow

extension UserInfo {
    public struct Scope: Codable, Hashable, Sendable {
        public enum Payload: Codable, Hashable, Sendable {
            case domain(_swiftType: _CodableSwiftType)
        }
        
        public var payload: Payload
        
        public init(payload: Payload) {
            self.payload = payload
        }
        
        public static func domain<DomainType>(_ domain: DomainType.Type) -> Self {
            assert(domain == DomainType.self)
            
            return Self(payload: .domain(_swiftType: _CodableSwiftType(from: domain)))
        }
    }
}

extension UserInfo {
    public struct ScopedTo<DomainType>: HeterogeneousDictionaryProtocol {
        open class _UserInfoKey {
            public typealias Domain = DomainType
        }
        
        public typealias _HeterogenousDictionaryKeyType = _UserInfoKey & UserInfoKey
        
        package var base: UserInfo
        
        package init(base: UserInfo) {
            self.base = base
        }
        
        public subscript<Key: UserInfoKey>(_ key: Key.Type) -> Key.Value {
            get {
                base.storage[key]
            } set {
                base.storage[key] = newValue
            }
        }
    }
    
    public subscript<DomainType>(domain domain: DomainType.Type) -> ScopedTo<DomainType> {
        get {
            ScopedTo(base: self[_scope: .domain(domain)])
        } set {
            self[_scope: .domain(domain)] = newValue.base
        }
    }
    
    public func scoped<DomainType>(
        to domain: DomainType.Type = DomainType.self
    ) -> ScopedTo<DomainType> {
        assert(domain == DomainType.self)
        
        return ScopedTo(base: self[_scope: .domain(domain)])
    }
}
