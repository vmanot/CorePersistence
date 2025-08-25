//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct AnyFileURL: Hashable, Sendable {
    public let base: URL
    
    fileprivate init(base: URL) {
        self.base = base
    }
}

// MARK: - Initializers

extension AnyFileURL {
    public init(_ url: URL) {
        self.init(base: url)
    }
    
    public init(_ directory: CanonicalFileDirectory) throws {
        try self.init(base: directory.toURL())
    }
}

// MARK: - Conformances

extension AnyFileURL: Codable {
    public init(from decoder: any Decoder) throws {
        self.init(base: try URL(from: decoder))
    }
    
    public func encode(to encoder: any Encoder) throws {
        try base.encode(to: encoder)
    }
}

extension AnyFileURL: _FileOrFolderRepresenting {
    public typealias FilesystemChild = AnyFileURL

    public func withResolvedURL<R>(
        perform operation: (URL) throws -> R
    ) throws -> R {
        try operation(_toURL())
    }

    public func _toURL() throws -> URL {
        base
    }

    public func decode(
        using coder: some _TopLevelFileDecoderEncoder
    ) throws -> Any? {
        try FileManager.default._decode(from: base, coder: coder)
    }
    
    public func encode<T>(
        _ contents: T,
        using coder: some _TopLevelFileDecoderEncoder
    ) throws {
        try FileManager.default._encode(contents, to: base, coder: coder)
    }
    
    @_spi(Internal)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func observeFilesystemChildrenAsynchronously() throws -> AsyncThrowingStream<AnyAsyncSequence<FilesystemChild>, Error> {
        try _DirectoryOrFileEventPublisher(url: base, queue: nil)
            .autoconnect()
            .prepend(())
            .values
            .eraseToThrowingStream()
            .map {
                AnyAsyncSequence {
                    _AsyncDirectoryIterator(directoryURL: base)
                }
                .map {
                    AnyFileURL(base: $0)
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

extension AnyFileURL: Identifiable {
    public var id: AnyHashable {
        base
    }
}
