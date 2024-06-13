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

public protocol _ReferenceFileDocument {
    associatedtype Snapshot
    
    typealias ReadConfiguration = _FileDocumentReadConfiguration
    typealias SnapshotConfiguration = ReferenceFileDocumentSnapshotConfiguration
    typealias WriteConfiguration = _FileDocumentWriteConfiguration
    
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

extension _ReferenceFileDocument {
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

extension _ReferenceFileDocument {
    func _opaque_fileWrapper(
        snapshot: Any,
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        let snapshot = try cast(snapshot, to: Snapshot.self)
        
        return try fileWrapper(snapshot: snapshot, configuration: configuration)
    }
}
