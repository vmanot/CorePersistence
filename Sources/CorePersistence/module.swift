//
// Copyright (c) Vatsal Manot
//

@_exported import Diagnostics
@_exported import Foundation
@_exported import Swallow
@_exported import SwallowMacrosClient

@_exported import _CoreIdentity
@_exported import _CSV
@_exported import _JSON
@_exported import _JSONSchema
@_exported import _ModularDecodingEncoding

public enum _module {
    private static var isInitialized: Bool = false
    
    public static func initialize() {
        guard !isInitialized else {
            return
        }
        
        defer {
            isInitialized = true
        }
        
        _HadeanSwiftTypeRegistry.register(UUID.self)
    }
}
