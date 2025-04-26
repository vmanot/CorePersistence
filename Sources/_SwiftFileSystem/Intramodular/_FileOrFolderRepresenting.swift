//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow
import System

/// A type that represents a file or folder.
public protocol _FileOrFolderRepresenting: Identifiable {
    associatedtype FilesystemChild: _FileOrFolderRepresenting = AnyFileURL
    
    func withResolvedURL<R>(
        perform operation: (URL) throws -> R
    ) throws -> R
    
    func _toURL() throws -> URL
    
    func decode(
        using coder: some _TopLevelFileDecoderEncoder
    ) throws -> Any?
    
    mutating func encode<T>(
        _ contents: T,
        using coder: some _TopLevelFileDecoderEncoder
    ) throws
    
    func child(
        at path: URL.RelativePath
    ) throws -> FilesystemChild
    
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
        using coder: some _TopLevelFileDecoderEncoder
    ) throws -> Any? {
        let url: URL = try self._toURL()
        let coder: _AnyTopLevelFileDecoderEncoder<Any> = try coder.__conversion()
        
        return try FileManager.default._decode(from: url, coder: coder)
    }
    
    public func decode<T>(
        _ type: T.Type,
        using coder: some _TopLevelFileDecoderEncoder
    ) throws -> T? {
        guard let contents = try self.decode(using: coder) else {
            return nil
        }
        
        return try cast(contents, to: T.self)
    }
    
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func observeFilesystemChildrenAsynchronously() throws -> AsyncThrowingStream<AnyAsyncSequence<FilesystemChild>, Error> {
        throw Never.Reason.unimplemented
    }
}

extension FileWrapper: _SwiftFileSystem._FileOrFolderRepresenting {
    public func withResolvedURL<R>(
        perform operation: (URL) throws -> R
    ) throws -> R {
        try operation(_toURL())
    }
    
    public func _toURL() throws -> URL {
        try self._contentsURL.unwrap()
    }
    
    public func decode(
        using coder: some _TopLevelFileDecoderEncoder
    ) throws -> Any? {
        throw Never.Reason.illegal
    }
    
    public func encode<T>(
        _ contents: T,
        using coder: some _TopLevelFileDecoderEncoder
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

// MARK: - Internal

extension FileWrapper {
    @nonobjc fileprivate var _contentsURL: URL? {
        self[instanceVariableNamed: "_contentsURL"] as? URL
    }
}
