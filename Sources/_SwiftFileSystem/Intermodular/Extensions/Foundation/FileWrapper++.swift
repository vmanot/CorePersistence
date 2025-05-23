//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow
import SwallowMacrosClient

extension FileWrapper {
    public convenience init(
        regularFileWithContents contents: Data,
        preferredFilename: String
    ) {
        self.init(regularFileWithContents: contents)
        
        self.preferredFilename = preferredFilename
    }
    
    public func firstAndOnlyChildWrapper() throws -> FileWrapper {
        try fileWrappers.unwrap().toCollectionOfOne().first.value
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func fileWrapper(
        at path: [String],
        directoryHint: URL.DirectoryHint
    ) throws -> FileWrapper {
        if path.isEmpty {
            return self
        } else {
            guard fileWrappers != nil else {
                throw _PlaceholderError()
            }
            
            var path = path
            
            let firstKey = path.removeFirst()
            
            if let firstChild = fileWrappers![firstKey] {
                return firstChild
            } else {
                let newChild: FileWrapper
                
                if !path.isEmpty || directoryHint == .isDirectory {
                    newChild = FileWrapper(directoryWithFileWrappers: [:])
                } else {
                    newChild = FileWrapper(regularFileWithContents: Data())
                }
                
                newChild.preferredFilename = firstKey
                
                addFileWrapper(newChild)
                
                return try newChild.fileWrapper(at: path, directoryHint: directoryHint)
            }
        }
    }
    
    public func removeAllFileWrappers() {
        for fileWrapper in (fileWrappers ?? [:]).values {
            removeFileWrapper(fileWrapper)
        }
    }
}

extension FileWrapper {
    public static func encodingRegularFileContents<T: Encodable>(
        _ x: T,
        coder: some TopLevelDataCoder
    ) throws -> FileWrapper {
        let data: Data = try coder.encode(x)
        
        return FileWrapper(regularFileWithContents: data)
    }
    
    public func decodeRegularFileContents<T: Decodable>(
        as type: T.Type = T.self,
        coder: some TopLevelDataCoder
    ) throws -> T {
        try coder.decode(from: regularFileContents.unwrap())
    }
}
