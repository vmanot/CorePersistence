//
// Copyright (c) Vatsal Manot
//

@_spi(Internal) import FoundationX
@_spi(Internal) import Swallow
import UniformTypeIdentifiers

public protocol _TopLevelFileDecoderEncoder {
    associatedtype DataType
    
    func __conversion<T>() throws -> _AnyTopLevelFileDecoderEncoder<T>
}

@_documentation(visibility: internal)
public enum __AnyTopLevelFileDecoderEncoder_RawValue {
    case document(_FileDocument.Type)
    case topLevelData(_AnyTopLevelDataCoder)
}

public struct _AnyTopLevelFileDecoderEncoder<DataType>: _TopLevelFileDecoderEncoder {
    public typealias RawValue = __AnyTopLevelFileDecoderEncoder_RawValue
    
    public let rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public func __conversion<T>() throws -> _AnyTopLevelFileDecoderEncoder<T> {
        _AnyTopLevelFileDecoderEncoder<T>(rawValue: rawValue)
    }
}

// MARK: - Initializers

extension _AnyTopLevelFileDecoderEncoder where DataType == Any {
    public init(
        _ coder: any TopLevelDataCoder,
        for type: any Codable.Type
    ) {
        self.init(rawValue: .topLevelData(.topLevelDataCoder(coder, forType: type)))
    }
    
    public init(
        _ documentType: any _FileDocument.Type,
        supportedTypes: [any _FileDocument.Type] = []
    ) {
        self.init(rawValue: .document(documentType))
    }
    
    public init(
        documentType: any _FileDocument.Type
    ) {
        self.init(rawValue: .document(documentType))
    }
    
    public init(
        _ coder: _AnyTopLevelDataCoder,
        supportedTypes: [Any.Type] = []
    ) {
        self.init(rawValue: .topLevelData(coder))
    }

    public init<Coder: TopLevelDataCoder, T>(
        _ coder: Coder,
        forUnsafelySerialized type: T.Type
    ) {
        let coder = _AnyTopLevelDataCoder.custom(
            .init(
                for: type,
                decode: { (data: Data) -> T in
                    try coder.decode(_UnsafelySerialized<T>.self, from: data).wrappedValue
                },
                encode: { (value: T) in
                    try coder.encode(_UnsafelySerialized(wrappedValue: value))
                }
            )
        )
        
        self.init(rawValue: .topLevelData(coder))
    }
}

// MARK: - Auxiliary

extension FileManager {
    func _decode(
        from url: URL,
        coder: some _TopLevelFileDecoderEncoder
    ) throws -> Any? {
        let coder: _AnyTopLevelFileDecoderEncoder<Any> = try coder.__conversion()

        switch coder.rawValue {
            case .document(let document):
                do {
                    return try document.init(configuration: .init(url: url))
                } catch {
                    if fileExists(at: url) {
                        throw error
                    } else {
                        return nil
                    }
                }
            case .topLevelData(let coder):
                guard let data = try fileExists(at: url) ? contents(ofSecurityScopedResource: url) : nil else {
                    return nil
                }
                
                return try coder.decode(from: data)
        }
    }
    
    func _encode<T>(
        _ value: T,
        to url: URL,
        coder: some _TopLevelFileDecoderEncoder
    ) throws {
        let coder: _AnyTopLevelFileDecoderEncoder<T> = try coder.__conversion()
        var url = url
        var endSecurityScopedAccess: (() -> Void)? = nil
        
        if !FileManager.default.fileExists(at: url.deletingLastPathComponent()) {
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }
        
        if !isReadableAndWritable(at: url) {
            if let securityScopedURL = try? URL._SavedBookmarks.bookmarkedURL(for: url) {
                if isReadableAndWritable(at: securityScopedURL) {
                    url = securityScopedURL
                }
            } else if let securityScopedParent = nearestAccessibleSecurityScopedAncestor(for: url) {
                guard securityScopedParent.startAccessingSecurityScopedResource() else {
                    assertionFailure("Failed to acquire permission to write to parent URL: \(securityScopedParent) (parent for \(url)")
                    
                    return
                }
                
                endSecurityScopedAccess = {
                    securityScopedParent.stopAccessingSecurityScopedResource()
                }
            }
        }
        
        switch coder.rawValue {
            case .document(let document):
                try document
                    ._opaque_fileWrapper(
                        for: value,
                        configuration: .init(url: url)
                    )
                    .write(
                        to: url,
                        options: [.atomic, .withNameUpdating],
                        originalContentsURL: nil
                    )
            case .topLevelData(let coder):
                let createDirectoriesIfNecessary = true
                
                try setContents(
                    of: url,
                    to: try coder.encode(value),
                    createDirectoriesIfNecessary: createDirectoriesIfNecessary
                )
        }
        
        endSecurityScopedAccess?()
    }
}
