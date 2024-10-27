//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift
import UniformTypeIdentifiers
import SwiftUI

public struct ReferenceFileDocumentSnapshotConfiguration {
    public let contentType: UTType?
    
    public init(
        contentType: UTType?
    ) {
        self.contentType = contentType
    }
}

public protocol PersistentReferenceFileDocument {
    associatedtype Snapshot
    
    typealias ReadConfiguration = PersistentFileDocumentReadConfiguration
    typealias SnapshotConfiguration = ReferenceFileDocumentSnapshotConfiguration
    typealias WriteConfiguration = PersistentFileDocumentWriteConfiguration
    
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

extension PersistentReferenceFileDocument {
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

// MARK: - Internal

extension PersistentReferenceFileDocument {
    func _opaque_fileWrapper(
        snapshot: Any,
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        let snapshot = try cast(snapshot, to: Snapshot.self)
        
        return try fileWrapper(snapshot: snapshot, configuration: configuration)
    }
}

// MARK: - Deprecated

@available(*, deprecated, renamed: "PersistentReferenceFileDocument")
public typealias _ReferenceFileDocument = PersistentReferenceFileDocument
