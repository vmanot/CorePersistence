//
// Copyright (c) Vatsal Manot
//

import Swallow
import UniformTypeIdentifiers

public protocol FileDocumentContentSelection: Codable, Hashable, Sendable {
    associatedtype Document: PersistentFileDocument
}

public enum DefaultFileDocumentContentSelection<Document: PersistentFileDocument>: FileDocumentContentSelection {
    case wholeDocument
}

public struct _ContentSelectionSpecified<Base: PersistentFileDocument, ContentSelection: FileDocumentContentSelection>: ContentSelectingFileDocument, PersistentFileDocument where ContentSelection.Document == Base {
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
        configuration: PersistentFileDocumentReadConfiguration
    ) throws {
        try self.init(base: .init(configuration: configuration))
    }
    
    public func fileWrapper(
        configuration: PersistentFileDocumentWriteConfiguration
    ) throws -> FileWrapper {
        try base._fileWrapper(configuration: configuration)
    }
}
