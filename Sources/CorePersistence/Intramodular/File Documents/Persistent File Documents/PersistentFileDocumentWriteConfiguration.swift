//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift
import UniformTypeIdentifiers

public struct PersistentFileDocumentWriteConfiguration {
    public let contentType: UTType?
    public let existingFile: FileWrapper?
    
    public init(
        contentType: UTType?,
        existingFile: FileWrapper?
    ) {
        self.contentType = contentType
        self.existingFile = existingFile
    }
}

extension PersistentFileDocumentWriteConfiguration {
    public init(
        existingFile: FileWrapper?,
        url: URL?
    ) throws {
        var _existingFile = existingFile
        
        if _existingFile == nil, let url = url, FileManager.default.fileExists(at: url) {
            _existingFile = try FileWrapper(url: url)
        }
        
        self.init(
            contentType: url.flatMap({ UTType(from: $0) }),
            existingFile: _existingFile
        )
    }
    
    @_disfavoredOverload
    public init(
        existingFile: _AsyncFileWrapper?,
        url: URL?
    ) throws {
        try self.init(existingFile: existingFile?.base, url: url)
    }
    
    public init(url: URL?) throws {
        try self.init(existingFile: nil, url: url)
    }
}
