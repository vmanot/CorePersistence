//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public struct _ModularCodingPluginContext {
    internal init() {
        
    }
}

public protocol _ModularCodingPlugin: Identifiable {
    typealias Context = _ModularCodingPluginContext
}
