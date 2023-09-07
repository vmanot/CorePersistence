//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow
import UniformTypeIdentifiers

public struct FileDocumentReadConfigurationX {
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

public struct ReferenceFileDocumentSnapshotConfiguration {
    public let contentType: UTType?
    
    public init(
        contentType: UTType?
    ) {
        self.contentType = contentType
    }
}

public struct FileDocumentWriteConfigurationX {
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

extension FileDocumentReadConfigurationX {
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

extension FileDocumentWriteConfigurationX {
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

public protocol FileDocumentX: _FileDocumentLike {
    typealias ReadConfiguration = FileDocumentReadConfigurationX
    typealias WriteConfiguration = FileDocumentWriteConfigurationX
    
    static var readableContentTypes: [UTType] { get }
    static var writableContentTypes: [UTType] { get }
    
    init(configuration: ReadConfiguration) throws
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
}

public protocol ReferenceFileDocumentX: _FileDocumentLike {
    associatedtype Snapshot
    
    typealias ReadConfiguration = FileDocumentReadConfigurationX
    typealias SnapshotConfiguration = ReferenceFileDocumentSnapshotConfiguration
    typealias WriteConfiguration = FileDocumentWriteConfigurationX
    
    static var readableContentTypes: [UTType] { get }
    static var writableContentTypes: [UTType] { get }
    
    init(configuration: ReadConfiguration) throws
    
    func snapshot(
        configuration: SnapshotConfiguration
    ) throws -> Snapshot
    
    func fileWrapper(
        snapshot: Snapshot,
        configuration: WriteConfiguration
    ) throws -> FileWrapper
}

extension FileDocumentX {
    public func _fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        try fileWrapper(configuration: configuration)
    }
}

extension ReferenceFileDocumentX {
    public func _fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        let contentType = Self.writableContentTypes.first // FIXME!
        let snapshot = try snapshot(
            configuration: SnapshotConfiguration(contentType: contentType)
        )
        
        return try fileWrapper(snapshot: snapshot, configuration: configuration)
    }
}

extension _FileDocumentLike {
    static func _opaque_fileWrapper(
        for value: Any,
        configuration: FileDocumentWriteConfigurationX
    ) throws -> FileWrapper {
        try cast(value, to: Self.self)._fileWrapper(configuration: configuration)
    }
}

extension ReferenceFileDocumentX {
    func _opaque_fileWrapper(
        snapshot: Any,
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        let snapshot = try cast(snapshot, to: Snapshot.self)
        
        return try fileWrapper(snapshot: snapshot, configuration: configuration)
    }
}

extension FileDocumentX {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}

extension ReferenceFileDocumentX {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}
