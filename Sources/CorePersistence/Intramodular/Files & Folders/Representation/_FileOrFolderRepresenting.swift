//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow
import System

/// A type that represents a file or folder.
public protocol _FileOrFolderRepresenting: Identifiable {
    associatedtype FilesystemChild: _FileOrFolderRepresenting = FileURL
    
    func _toURL() throws -> URL
    
    func decode(using coder: _AnyConfiguredFileCoder) throws -> Any?
    
    mutating func encode<T>(_ contents: T, using coder: _AnyConfiguredFileCoder) throws
    
    func child(at path: URL.RelativePath) throws -> FilesystemChild
    
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func observeFilesystemChildrenAsynchronously() throws -> AsyncThrowingStream<AnyAsyncSequence<FilesystemChild>, Error>
}

extension _FileOrFolderRepresenting {
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func _opaque_observeFilesystemChildrenAsynchronously() throws -> AsyncThrowingStream<AnyAsyncSequence<any _FileOrFolderRepresenting>, Error> {
        try observeFilesystemChildrenAsynchronously().map { sequence in
            sequence
                .map {
                    $0 as (any _FileOrFolderRepresenting)
                }
                .eraseToAnyAsyncSequence()
        }
    }
}

extension _FileOrFolderRepresenting {
    public func _toURL() throws -> URL {
        throw Never.Reason.unimplemented
    }
    
    public func decode(
        using coder: _AnyConfiguredFileCoder
    ) throws -> Any? {
        throw Never.Reason.unimplemented
    }
    
    public func decode<T>(
        _ type: T.Type,
        using coder: _AnyConfiguredFileCoder
    ) throws -> T? {
        guard let contents = try self.decode(using: coder) else {
            return nil
        }
        
        return try cast(contents, to: T.self)
    }
    
    @_spi(Internal)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func observeFilesystemChildrenAsynchronously() throws -> AsyncThrowingStream<AnyAsyncSequence<FilesystemChild>, Error> {
        throw Never.Reason.unimplemented
    }
}

extension FileWrapper: _FileOrFolderRepresenting {
    public func _toURL() throws -> URL {
        throw Never.Reason.illegal
    }
    
    public func decode(
        using coder: _AnyConfiguredFileCoder
    ) throws -> Any? {
        throw Never.Reason.illegal
    }
    
    public func encode<T>(
        _ contents: T,
        using coder: _AnyConfiguredFileCoder
    ) throws {
        throw Never.Reason.illegal
    }
    
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func observeFilesystemChildrenAsynchronously() throws -> AsyncThrowingStream<AnyAsyncSequence<FilesystemChild>, Error> {
        throw Never.Reason.illegal
    }
    
    public func child(
        at path: URL.RelativePath
    ) throws -> FilesystemChild {
        throw Never.Reason.illegal
    }
}
