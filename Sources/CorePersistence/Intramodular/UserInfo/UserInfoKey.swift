//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol UserInfoKey<Domain> {
    associatedtype Domain
    associatedtype Value
    
    static var defaultValue: Value { get }
    
    /// The name of the variable as declared in source code.
    static var _swift_variableIdentifier: String { get } // TODO: Wrap into a better construct
}

// MARK: - Auxiliary

public protocol __TopLevelUserInfoKey {
    typealias Domain = Never
}

public protocol _TopLevelUserInfoKey: __TopLevelUserInfoKey, UserInfoKey where Domain == Never {
    
}
