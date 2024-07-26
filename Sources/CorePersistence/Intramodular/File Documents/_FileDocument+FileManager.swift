//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow
import UniformTypeIdentifiers

extension FileManager {
    public func isFileOfType(
        _ types: some Sequence<UTType>,
        at url: URL
    ) throws -> Bool {
        let types = Set(types)
        
        try _tryAssert(fileExists(at: url))
        
        guard let existingFileType = UTType(from: url) else {
            assertionFailure()
            
            return false
        }
        
        let result = types.contains(where: { $0 == existingFileType || $0.isSubtype(of: existingFileType) })
        
        return result
    }
    
    public func _sanityCheckWritability<T: _FileDocument>(
        ofType type: T.Type,
        at url: URL
    ) throws {
        if fileExists(at: url) {
            try _tryAssert(try isFileOfType(type.writableContentTypes, at: url))
        } else {
            try _tryAssert(isReadableAndWritable(at: url))
        }
    }
    
    public func decode<T: _FileDocument>(
        _ type: T.Type,
        from url: URL
    ) throws -> T {
        try T(configuration :_FileDocumentReadConfiguration(url: url))
    }
    
    public func decode<T: _FileDocument>(
        _ type: Optional<T>.Type,
        from url: URL
    ) throws -> Optional<T> {
        if fileExists(at: url) {
            return try decode(T.self, from: url)
        } else {
            return nil
        }
    }
    
    public func decode<T: _FileDocument>(
        _ documents: [URL.RelativePath: T].Type,
        from url: URL
    ) throws -> [URL.RelativePath: T] {
        let fileURL = url._actuallyStandardizedFileURL
        
        var result: [URL.RelativePath: T] = [:]
        
        for itemURL in try self.contentsOfDirectory(at: url) {
            let itemFileURL = itemURL._actuallyStandardizedFileURL
            
            do {
                if try isFileOfType(T.readableContentTypes, at: itemURL) {
                    let path = try itemFileURL.path(relativeTo: fileURL)
                    
                    result[path] = try T(configuration: _FileDocumentReadConfiguration(url: fileURL))
                }
            } catch {
                assertionFailure(error)
            }
        }
        
        try _tryAssert(isDirectory(at: url))
        
        return result
    }
    
    public func encode<T: _FileDocument>(
        _ documents: [URL.PathComponent: T],
        to url: URL
    ) throws {
        for (key, value) in documents {
            let itemURL: URL = url.appending(key)
            let fileExists = fileExists(at: itemURL)
            
            try _sanityCheckWritability(ofType: T.self, at: itemURL)
            
            let writeConfiguration = try _FileWrapperDocument.WriteConfiguration(url: itemURL)
            let fileWrapper = try value.fileWrapper(configuration: writeConfiguration)
            
            try fileWrapper.write(to: itemURL, originalContentsURL: fileExists ? itemURL : nil)
        }
    }
}
