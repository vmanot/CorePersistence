//
// Copyright (c) Vatsal Manot
//

import Foundation

#if canImport(ObjectiveC)
import ObjectiveC

extension FileWrapper {
    @nonobjc public var _contentsURLInstanceVariableValue: URL? {
        guard let instanceVariable = class_getInstanceVariable(FileWrapper.self, "_contentsURL") else {
            return nil
        }
        
        return object_getIvar(self, instanceVariable) as? URL
    }
}
#else
extension FileWrapper {
    @nonobjc public var _contentsURLInstanceVariableValue: URL? {
        nil
    }
}
#endif
