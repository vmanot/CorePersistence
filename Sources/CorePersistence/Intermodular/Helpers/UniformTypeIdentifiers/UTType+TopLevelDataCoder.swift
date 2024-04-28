//
// Copyright (c) Vatsal Manot
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    func _suggestedTopLevelDataCoder(
        contentType: UTType?
    ) -> (any TopLevelDataCoder)? {
        let detectedContentType: UTType
        
        if let contentType {
            detectedContentType = contentType
        } else if let inferredContentType = UTType(from: self) {
            detectedContentType = inferredContentType
        } else {
            return nil
        }
        
        return detectedContentType._suggestedTopLevelDataCoder()
    }
}

extension UTType {
    public func _suggestedTopLevelDataCoder() -> (any TopLevelDataCoder)? {
        switch self {
            case .propertyList:
                return PropertyListCoder()
            case .json:
                return JSONCoder()
            default:
                return nil
        }
    }
}
