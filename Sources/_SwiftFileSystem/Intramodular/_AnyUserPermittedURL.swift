//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct _AnyUserPermittedURL: Hashable, Sendable {
    public let base: URL
    
    fileprivate init(base: URL) {
        self.base = base
    }
}

// MARK: - Initializers

extension _AnyUserPermittedURL {
    public init(_ url: URL) {
        self.init(base: url)
    }
    
    public init(_ directory: CanonicalFileDirectory) throws {
        try self.init(base: directory.toURL())
    }
}

// MARK: - Conformances

extension _AnyUserPermittedURL: Codable {
    public init(from decoder: any Decoder) throws {
        self.init(base: try URL(from: decoder))
    }
    
    public func encode(to encoder: any Encoder) throws {
        if Thread.isMainThread {
            try MainActor.unsafeAssumeIsolated {
                try FileManager.default.withUserGrantedAccess(to: base) { url in
                    try base.encode(to: encoder)
                }
            }
        } else {
            try base.encode(to: encoder)
        }
    }
}

extension _AnyUserPermittedURL: _FileOrFolderRepresenting {
    public func withResolvedURL<R>(
        perform operation: (URL) throws -> R
    ) throws -> R {
        var result: R!
        
        if Thread.isMainThread {
            try MainActor.unsafeAssumeIsolated {
                try FileManager.default.withUserGrantedAccess(to: base) { url in
                    result = try operation(url)
                }
            }
        } else {
            result = try operation(base)
        }
        
        return result
    }
    
    public func _toURL() throws -> URL {
        if Thread.isMainThread {
            try MainActor.unsafeAssumeIsolated {
                try FileManager.default.withUserGrantedAccess(to: base) { url in
                    url
                }
            }
        } else {
            base
        }
    }
    
    public func decode(
        using coder: some _TopLevelFileDecoderEncoder
    ) throws -> Any? {
        if Thread.isMainThread {
            try MainActor.unsafeAssumeIsolated {
                try FileManager.default.withUserGrantedAccess(to: base) { url in
                    try FileManager.default._decode(from: url, coder: coder)
                }
            }
        } else {
            try FileManager.default._decode(from: base, coder: coder)
        }
    }
    
    public func encode<T>(
        _ contents: T,
        using coder: some _TopLevelFileDecoderEncoder
    ) throws {
        if Thread.isMainThread {
            try MainActor.unsafeAssumeIsolated {
                try FileManager.default.withUserGrantedAccess(to: base) { url in
                    try FileManager.default._encode(contents, to: url, coder: coder)
                }
            }
        } else {
            try FileManager.default._encode(contents, to: base, coder: coder)
        }
    }
    
    @_spi(Internal)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func observeFilesystemChildrenAsynchronously() throws -> AsyncThrowingStream<AnyAsyncSequence<_AnyUserPermittedURL>, Error> {
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
                    _AnyUserPermittedURL(base: $0)
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

extension _AnyUserPermittedURL: Identifiable {
    public var id: AnyHashable {
        base
    }
}
