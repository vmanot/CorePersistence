//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct _UnsafeSerializationPlugin: Hashable, _ModularCodingPlugin {
    public var id: AnyHashable {
        ObjectIdentifier(_UnsafeSerializationPlugin.self)
    }
    
    public init() {
        
    }
}

extension _ModularCodingPlugin where Self == _UnsafeSerializationPlugin {
    public static var allowUnsafeSerialization: Self {
        Self()
    }
}
