//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow
import SwiftUI
import UniformTypeIdentifiers

public protocol _FileDocument {
    typealias ReadConfiguration = _FileDocumentReadConfiguration
    typealias WriteConfiguration = _FileDocumentWriteConfiguration
    
    static var readableContentTypes: [UTType] { get }
    static var writableContentTypes: [UTType] { get }
    
    init(configuration: ReadConfiguration) throws
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
}

extension _FileDocument {
    @_disfavoredOverload
    public func _fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        try fileWrapper(configuration: configuration)
    }
}

extension _FileDocument {
    static func _opaque_fileWrapper(
        for value: Any,
        configuration: _FileDocumentWriteConfiguration
    ) throws -> FileWrapper {
        try cast(value, to: Self.self)._fileWrapper(configuration: configuration)
    }
}

extension _FileDocument {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}

extension _ReferenceFileDocument {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}

extension _ReferenceFileDocument where Self: _FileDocument {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}
