//
// Copyright (c) Vatsal Manot
//

import UniformTypeIdentifiers

public protocol _FileDocumentLike {
    static var readableContentTypes: [UTType] { get }
    static var writableContentTypes: [UTType] { get }
    
    init(configuration: FileDocumentReadConfigurationX) throws
    
    func _fileWrapper(configuration: FileDocumentWriteConfigurationX) throws -> FileWrapper
}
