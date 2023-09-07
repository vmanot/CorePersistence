//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public enum _module {
    private static var isInitialized: Bool = false
    
    public static func initialize() {
        guard !isInitialized else {
            return
        }
        
        defer {
            isInitialized = true
        }
        
        _UniversalTypeRegistry.register(UUID.self)
    }
}
