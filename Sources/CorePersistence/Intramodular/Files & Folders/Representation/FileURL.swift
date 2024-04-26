//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct FileURL {
    public let base: URL
    
    fileprivate init(base: URL) {
        self.base = base
    }
}

// MARK: - Initializers

extension FileURL {
    public init(_ url: URL) {
        self.init(base: url)
    }
    
    public init(_ directory: CanonicalFileDirectory) throws {
        try self.init(base: directory.toURL())
    }
}

// MARK: - Conformances

extension FileURL: _FileOrFolderRepresenting {
    public typealias FilesystemChild = FileURL

    public func _toURL() throws -> URL {
        base
    }

    public func decode(
        using coder: _AnyConfiguredFileCoder
    ) throws -> Any? {
        try FileManager.default._decode(from: base, coder: coder)
    }
    
    public func encode<T>(
        _ contents: T,
        using coder: _AnyConfiguredFileCoder
    ) throws {
        try FileManager.default._encode(contents, to: base, coder: coder)
    }
    
    @_spi(Internal)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func observeFilesystemChildrenAsynchronously() throws -> AsyncThrowingStream<AnyAsyncSequence<FilesystemChild>, Error> {
        try _DirectoryEventsPublisher(url: base, queue: nil)
            .autoconnect()
            .prepend(())
            .values
            .eraseToThrowingStream()
            .map {
                AnyAsyncSequence {
                    _AsyncDirectoryIterator(directoryURL: base)
                }
                .map {
                    FileURL(base: $0)
                }
                .eraseToAnyAsyncSequence()
            }
            .eraseToThrowingStream()
    }
    
    public func child(
        at path: URL.RelativePath
    ) -> FilesystemChild {
        Self(base: base.appendingPathComponent(path.path))
    }
}

extension FileURL: Identifiable {
    public var id: AnyHashable {
        base
    }
}
