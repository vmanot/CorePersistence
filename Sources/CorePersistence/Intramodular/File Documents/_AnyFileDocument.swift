//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Merge
import Swallow
import UniformTypeIdentifiers

public final class _AnyFileDocument: ObservableObject {
    private enum _Error: Error {
        case unsupportedInitialization(from: Any)
        case unsupportedTypeCast(to: Any.Type)
    }
    
    @Published private var _base: any _FileDocumentLike
    
    public var base: any _FileDocumentLike {
        get {
            _base
        } set {
            _base = newValue
        }
    }
    
    init(base: any _FileDocumentLike) {
        self._base = base
    }
}

// MARK: - Initializers

extension _AnyFileDocument {
    public convenience init(configuration: ReadConfiguration) throws {
        self.init(base: try _FileWrapperDocument(configuration: configuration))
    }
    
    public convenience init(url: URL) throws {
        try self.init(configuration: .init(url: url))
    }
    
    public convenience init(_ document: any FileDocumentX) {
        self.init(base: document)
    }
    
    public convenience init(_ value: Any) throws {
        if let value = value as? _FileDocumentLike {
            self.init(base: value)
        } else if let value = value as? Codable {
            self.init(_codable: value)
        } else {
            throw _Error.unsupportedInitialization(from: value)
        }
    }
    
    private convenience init<T: Codable>(_codable value: T) {
        assert(!(value is _FileDocumentLike))
        
        self.init(base: _JSONCodingDocument(value: value))
    }
}

// MARK: - Extensions

extension _AnyFileDocument {
    public var regularFileContents: Data {
        get throws {
            if let base = base as? _FileWrapperDocument {
                return try base.regularFileContents
            } else {
                let fileWrapper = try _fileWrapper(configuration: .init(contentType: nil, existingFile: nil))
                
                return try _FileWrapperDocument(fileWrapper: fileWrapper).regularFileContents
            }
        }
    }
}

extension _AnyFileDocument {
    public func _typedAccessor<T>(_ type: T.Type) -> _NonAsyncAndAsyncAccessor<Void, T> {
        func _setSynchronously(_ newValue: T) throws {
            if let newValue = newValue as? _FileDocumentLike {
                self.base = newValue
            } else if let newValue = newValue as? Codable {
                try newValue._opaque_encode(toJSONCodingDocument: &self.base)
            } else {
                throw _PlaceholderError()
            }
        }
        
        return _NonAsyncAndAsyncAccessor(
            nonAsync: .init(
                get: {
                    try self._loadSynchronously(type)
                },
                set: _setSynchronously
            ),
            async: .init(
                get: {
                    try await self.load(type)
                },
                set: _setSynchronously
            )
        )
    }
}

extension _AnyFileDocument {
    public func cast<T>(
        to type: T.Type
    ) async throws -> T {
        try await _cast(to: type, preserveResultInPlace: false)
    }
    
    public func load<T>(
        _ type: T.Type
    ) async throws -> T {
        try await _cast(to: type, preserveResultInPlace: true)
    }
    
    private func _cast<T>(
        to type: T.Type,
        preserveResultInPlace: Bool
    ) async throws -> T {
        if let type = type as? _FileDocumentLike.Type {
            return try await Swallow.cast(_cast(to: type, preserveResultInPlace: preserveResultInPlace), to: T.self)
        } else if let type = type as? Codable.Type {
            return try await Swallow.cast(_cast(to: type, preserveResultInPlace: preserveResultInPlace), to: T.self)
        } else {
            throw _Error.unsupportedTypeCast(to: type)
        }
    }
    
    private func _cast<T: Codable>(
        to type: T.Type,
        preserveResultInPlace: Bool
    ) async throws -> T {
        if let base = base as? _JSONCodingDocument<T> {
            return base.value
        } else if base is _FileWrapperDocument {
            let document = try await _cast(
                to: _JSONCodingDocument<T>.self,
                preserveResultInPlace: preserveResultInPlace
            )
            
            return document.value
        } else {
            throw _Error.unsupportedTypeCast(to: type)
        }
    }
    
    private func _cast<T: _FileDocumentLike>(
        to type: T.Type,
        preserveResultInPlace: Bool
    ) async throws -> T {
        if let base = base as? T {
            return base
        } else if let base = base as? _FileWrapperDocument {
            let document = try T.init(configuration: .init(contentType: nil, file: base.fileWrapper))
            
            if preserveResultInPlace {
                await MainActor.run {
                    self.base = document
                }
            }
            
            return document
        } else {
            return try Swallow.cast(base, to: type)
        }
    }
}

extension _AnyFileDocument {
    public func _loadSynchronously<T>(
        _ type: T.Type
    ) throws -> T {
        try _castSynchronously(to: type, preserveResultInPlace: true)
    }
    
    private func _castSynchronously<T>(
        to type: T.Type,
        preserveResultInPlace: Bool
    ) throws -> T {
        if let type = type as? _FileDocumentLike.Type {
            return try Swallow.cast(_castSynchronously(to: type, preserveResultInPlace: preserveResultInPlace), to: T.self)
        } else if let type = type as? Codable.Type {
            return try Swallow.cast(_castSynchronously(to: type, preserveResultInPlace: preserveResultInPlace), to: T.self)
        } else {
            throw _Error.unsupportedTypeCast(to: type)
        }
    }
    
    private func _castSynchronously<T: Codable>(
        to type: T.Type,
        preserveResultInPlace: Bool
    ) throws -> T {
        if let base = base as? _JSONCodingDocument<T> {
            return base.value
        } else if base is _FileWrapperDocument {
            return try _castSynchronously(
                to: _JSONCodingDocument<T>.self,
                preserveResultInPlace: preserveResultInPlace
            ).value
        } else {
            throw _Error.unsupportedTypeCast(to: type)
        }
    }
    
    private func _castSynchronously<T: _FileDocumentLike>(
        to type: T.Type,
        preserveResultInPlace: Bool
    ) throws -> T {
        if let base = base as? T {
            return base
        } else if let base = base as? _FileWrapperDocument {
            let document = try T.init(configuration: .init(contentType: nil, file: base.fileWrapper))
            
            if preserveResultInPlace {
                self.base = document
            }
            
            return document
        } else {
            return try Swallow.cast(base, to: type)
        }
    }
}

// MARK: - Conformances

extension _AnyFileDocument: ReferenceFileDocumentX {
    public enum Snapshot {
        case data(Data)
        case document(any FileDocumentX)
        case documentSnapshot(Any, document: any ReferenceFileDocumentX)
    }
    
    public func snapshot(
        configuration: SnapshotConfiguration
    ) throws -> Snapshot {
        if let base = base as? FileDocumentX {
            return .document(base)
        } else if let base = base as? any ReferenceFileDocumentX {
            let snapshot = try base.snapshot(configuration: configuration)
            
            return .documentSnapshot(snapshot, document: base)
        } else {
            throw Never.Reason.unexpected
        }
    }
    
    public func fileWrapper(
        snapshot: Snapshot,
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        switch snapshot {
            case .data(let data):
                return FileWrapper(regularFileWithContents: data)
            case .document(let document):
                return try document.fileWrapper(configuration: configuration)
            case .documentSnapshot(let snapshot, let document):
                return try document._opaque_fileWrapper(
                    snapshot: snapshot,
                    configuration: configuration
                )
        }
    }
}

// MARK: - Auxiliary

extension Decodable where Self: Encodable {
    fileprivate static func _opaque_decode(
        fromJSONCodingDocument document: _FileDocumentLike
    ) throws -> Any {
        if let document = document as? _FileWrapperDocument {
            return try _JSONCodingDocument<Self>(
                configuration: .init(
                    contentType: .json,
                    file: document.fileWrapper
                )
            ).value
        } else {
            return try cast(document, to: _JSONCodingDocument<Self>.self).value
        }
    }
    
    fileprivate func _opaque_encode(
        toJSONCodingDocument document: inout _FileDocumentLike
    ) throws {
        try _tryAssert(document is _JSONCodingDocument<Self> || document is _FileWrapperDocument)
        
        document = _JSONCodingDocument(value: self)
    }
}
