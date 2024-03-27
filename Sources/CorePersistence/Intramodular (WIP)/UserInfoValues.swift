//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct UserInfoValues<DomainType> {
    public typealias Domain = DomainType
}

/*extension UserInfoValues<Int> {
    public struct Foo: UserInfoKey {
        public typealias Domain = UserInfoValues.Domain
        public typealias Value = Int?
    }
    
    public var foo: Foo {
        .init()
    }
}*/
