//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public protocol _ObservableFileDirectoryOperation {
    
}

extension _ObservableFileDirectoryType where Self: _ObservableFileDirectory {
    public func copy<T: Collection>(
        _ keyPath: KeyPath<Self, T>,
        toDirectory directory: URLRepresentable,
        replaceExisting: Bool
    ) throws where T.Element: URLConvertible {
        let source = FileOrFolderTarget(keyPath)
        let destination = FileOrFolderTarget(directory)
        let operation = CopyOperation(source: source, destination: destination, replaceExisting: replaceExisting)
        
        let items = try resolve(operation, \.source, as: [URL].self)
        
        try cocoaFileManager.copyFolders(from: items, to: directory, replaceExisting: replaceExisting)
    }
    
    public func copy<T: Collection>(
        _ keyPath: KeyPath<Self, T>,
        to url: URL,
        replaceExisting: Bool
    ) throws where T.Element: URLConvertible {
        try url.withResolvedURL { url in
            try _tryAssert(cocoaFileManager.isDirectory(at: url))
            
            return try copy(keyPath, to: url, replaceExisting: replaceExisting)
        }
    }
}

extension _ObservableFileDirectory {
    public protocol FileOrFolderTargetExpression {
        
    }
    
    public struct FileOrFolderTarget {
        public struct KeyPathExpression: FileOrFolderTargetExpression {
            public let keyPath: AnyKeyPath
        }
        
        public let expression: any FileOrFolderTargetExpression
        
        public init(_ expression: some FileOrFolderTargetExpression) {
            self.expression = expression
        }
        
        public init(_ expression: some URLRepresentable) {
            self.expression = expression.url
        }
        
        public init<Root: _ObservableFileDirectoryType, Value: Collection>(
            _ keyPath: KeyPath<Root, Value>
        ) where Value.Element: URLConvertible {
            self.expression = KeyPathExpression(keyPath: keyPath)
        }
    }
        
    public struct CopyOperation: _ObservableFileDirectoryOperation {
        public let source: FileOrFolderTarget
        public let destination: FileOrFolderTarget
        public let replaceExisting: Bool
        
        public init(
            source: FileOrFolderTarget,
            destination: FileOrFolderTarget,
            replaceExisting: Bool
        ) {
            self.source = source
            self.destination = destination
            self.replaceExisting = replaceExisting
        }
    }
}

extension URL: _ObservableFileDirectory.FileOrFolderTargetExpression {
    
}
