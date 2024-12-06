//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift
import UniformTypeIdentifiers

public struct PersistentFileDocumentReadConfiguration {
    public let contentType: UTType?
    public let file: FileWrapper
    
    public init(
        contentType: UTType?,
        file: FileWrapper
    ) {
        self.contentType = contentType
        self.file = file
    }
    
    public init(
        contentType: UTType?,
        file: _AsyncFileWrapper
    ) {
        self.init(contentType: contentType, file: file.base)
    }
}

extension PersistentFileDocumentReadConfiguration {
    public init(file: FileWrapper, url: URL?) {
        self.init(
            contentType: url.flatMap({ UTType(from: $0) }),
            file: file
        )
    }
    
    public init(file: _AsyncFileWrapper, url: URL?) {
        self.init(
            contentType: url.flatMap({ UTType(from: $0) }),
            file: file
        )
    }
    
    public init(url: URL) throws {
        try self.init(file: FileWrapper(url: url), url: url)
    }
}
