//
// Copyright (c) Vatsal Manot
//

import Swallow
import UniformTypeIdentifiers

public protocol FileDocumentContentSelection: Codable, Hashable, Sendable {
    associatedtype Document: _FileDocument
}

public enum DefaultFileDocumentContentSelection<Document: _FileDocument>: FileDocumentContentSelection {
    case wholeDocument
}

public struct _ContentSelectionSpecified<Base: _FileDocument, ContentSelection: FileDocumentContentSelection>: ContentSelectingFileDocument, _FileDocument where ContentSelection.Document == Base {
    public static var readableContentTypes: [UTType] {
        Base.readableContentTypes
    }
    
    public static var writableContentTypes: [UTType] {
        Base.writableContentTypes
    }
    
    public let base: Base
    
    public init(base: Base) {
        self.base = base
    }
    
    public init(
        configuration: _FileDocumentReadConfiguration
    ) throws {
        try self.init(base: .init(configuration: configuration))
    }
    
    public func fileWrapper(
        configuration: _FileDocumentWriteConfiguration
    ) throws -> FileWrapper {
        try base._fileWrapper(configuration: configuration)
    }
}
