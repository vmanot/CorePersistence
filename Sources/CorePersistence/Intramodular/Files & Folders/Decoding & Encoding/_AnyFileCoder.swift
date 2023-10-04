//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import UniformTypeIdentifiers

public struct _AnyConfiguredFileCoder {
    public enum RawValue {
        case document(_FileDocumentLike.Type)
        case topLevelData(_AnyTopLevelDataCoder)
    }
    
    public let rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public init(
        _ documentType: any _FileDocumentLike.Type,
        supportedTypes: [any _FileDocumentLike.Type] = []
    ) {
        self.init(rawValue: .document(documentType))
    }
    
    public init(
        _ coder: _AnyTopLevelDataCoder,
        supportedTypes: [Any.Type] = []
    ) {
        self.init(rawValue: .topLevelData(coder))
    }
}

// MARK: - Auxiliary

extension FileManager {
    func _decode(
        from url: URL,
        coder: _AnyConfiguredFileCoder
    ) throws -> Any? {
        switch coder.rawValue {
            case .document(let document):
                return try document.init(configuration: .init(url: url))
            case .topLevelData(let coder):
                guard let data = try fileExists(at: url) ? contents(of: url) : nil else {
                    return nil
                }
                
                return try coder.decode(from: data)
        }
    }
    
    func _encode<T>(
        _ value: T,
        to url: URL,
        coder: _AnyConfiguredFileCoder
    ) throws {
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
    }
}

extension URL {
    func _suggestedTopLevelDataCoder(
        contentType: UTType?
    ) -> (any TopLevelDataCoder)? {
        let detectedContentType: UTType
        
        if let contentType {
            detectedContentType = contentType
        } else if let inferredContentType = UTType(from: self) {
            detectedContentType = inferredContentType
        } else {
            return nil
        }
        
        return detectedContentType._suggestedTopLevelDataCoder()
    }
}

extension UTType {
    fileprivate func _suggestedTopLevelDataCoder() -> (any TopLevelDataCoder)? {
        switch self {
            case .propertyList:
                return PropertyListCoder()
            case .json:
                return JSONCoder()
            default:
                return nil
        }
    }
}
