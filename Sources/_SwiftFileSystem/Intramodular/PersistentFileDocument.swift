//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow
import SwiftUI
import UniformTypeIdentifiers

public protocol PersistentFileDocument {
    typealias ReadConfiguration = PersistentFileDocumentReadConfiguration
    typealias WriteConfiguration = PersistentFileDocumentWriteConfiguration
    
    static var readableContentTypes: [UTType] { get }
    static var writableContentTypes: [UTType] { get }
    
    init(configuration: ReadConfiguration) throws
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
}

extension PersistentFileDocument {
    public init(url: some URLConvertible) throws {
        self = try url.withResolvedURL { (url: URL) in
            try Self(
                configuration: PersistentFileDocumentReadConfiguration(
                    url: url
                )
            )
        }
    }
}

extension PersistentFileDocument {
    @_disfavoredOverload
    public func _fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        try fileWrapper(configuration: configuration)
    }
}

extension PersistentFileDocument {
    public static func _opaque_fileWrapper(
        for value: Any,
        configuration: PersistentFileDocumentWriteConfiguration
    ) throws -> FileWrapper {
        try cast(value, to: Self.self)._fileWrapper(configuration: configuration)
    }
}

extension PersistentFileDocument {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}

extension PersistentReferenceFileDocument {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}

extension PersistentReferenceFileDocument where Self: PersistentFileDocument {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}

// MARK: - Deprecated

@available(*, deprecated, renamed: "PersistentFileDocument")
public typealias _FileDocument = PersistentFileDocument
