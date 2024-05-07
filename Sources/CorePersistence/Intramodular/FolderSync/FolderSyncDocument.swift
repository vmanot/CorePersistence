//
// Copyright (c) Vatsal Manot
//

import SwiftUI
import Runtime
import UniformTypeIdentifiers

public struct FolderSyncDocument: Codable, Hashable, Identifiable, FileDocument {
    public static var readableContentTypes: [UTType] {
        writableContentTypes
    }
    
    public static var writableContentTypes: [UTType] {
        [UTType("com.vmanot.foldersync.package")!]
    }
    
    public let url: URL.Bookmark?
    public let targets: [URL.RelativePath: FileOrFolderAlias]
    
    public var id: URL {
        try! url!.resolve().url
    }
    
    public init() {
        self.url = nil
        self.targets = [:]
    }
    
    public init(url: URL) throws {
        self.url = try URL.Bookmark(for: url)
        self.targets = try FileManager.default
            .enumerateRelativePaths(forDirectory: url)
            ._compactMapToDictionary(
                key: { $0 },
                value: { path in
                    try? FileOrFolderAlias(url: url.appending(path))
                }
            )
    }
    
    public init(configuration: ReadConfiguration) throws {
        guard configuration.file.isDirectory else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        
        let url = try configuration.file._contentsURL.unwrap()
        
        try  self.init(url: url)
    }
    
    public func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        .init()
    }
}

// MARK: - Auxiliary

extension FileWrapper {
    @nonobjc fileprivate var _contentsURL: URL? {
        self[instanceVariableNamed: "_contentsURL"] as? URL
    }
}
