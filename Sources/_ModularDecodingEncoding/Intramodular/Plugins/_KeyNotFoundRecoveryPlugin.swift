//
// Copyright (c) Vatsal Manot
//

import _CoreIdentity
import Foundation
import Diagnostics
import Swallow

/// Will force the decoder to recover types that can be initialized using `init()`, `nil`, or `[]`.
public final class _KeyNotFoundRecoveryPlugin: _ModularCodingPlugin {
    public init() {
        
    }
}

extension _ModularCodingPlugin where Self == _KeyNotFoundRecoveryPlugin {
    public static var _recoverFromKeyNotFound: Self {
        Self()
    }
}
