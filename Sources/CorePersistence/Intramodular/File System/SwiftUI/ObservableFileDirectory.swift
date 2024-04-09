//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Merge
import System
import Swift

public protocol ObservableFileDirectoryType: Logging, ObservableObject {
    var cocoaFileManager: FileManager { get }
}

open class ObservableFileDirectory: ObservableFileDirectoryType {
    public let url: URL
    public let cocoaFileManager: FileManager
    
    private var fileSource: DispatchSourceFileSystemObject?
    
    @Published private var directoryDescriptor: FileDescriptor?
    @Published private var directorySource: DispatchSourceFileSystemObject?
    
    @Published private(set) var children: [URL]?
    
    public init(url: URL) {
        self.url = url
        self.cocoaFileManager = FileManager.default
        
        Task { @MainActor in
            populateChildren()
            
            do {
                try self.beginObserving()
            } catch {
                logger.error(error)
            }
        }
    }
    
    public convenience init(location: some URLRepresentable) {
        self.init(url: location.url)
    }
    
    open func resolve<OperationType: _ObservableFileDirectoryOperation, MemberType, TargetType>(
        _ operation: OperationType,
        _ keyPath: KeyPath<OperationType, MemberType>,
        as targetType: TargetType.Type
    ) throws -> TargetType {
        let member = operation[keyPath: keyPath]
        
        if let member = member as? FileOrFolderTarget, targetType == [URL].self {
            if let expression = member.expression as? FileOrFolderTarget.KeyPathExpression {
                return try expression.keyPath._accessValue(of: self, as: Array<any _URLConvertible>.self).map({ $0.url }) as! TargetType
            }
        }
        
        TODO.unimplemented
    }

    @MainActor
    private func beginObserving() throws {
        try stopObserving()
        
        let directoryDescriptor = try FileDescriptor.open(FilePath(fileURL: url), .readOnly, options: .eventOnly)
        let directorySource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: directoryDescriptor.rawValue, eventMask: .all, queue: DispatchQueue.global(qos: .userInitiated))
        
        directorySource.setEventHandler { [weak self] in
            guard let `self` = self else {
                return
            }
                        
            Task { @MainActor in
                self.objectWillChange.send()

                self.populateChildren()
            }
        }
        
        directorySource.resume()
        
        self.directoryDescriptor = directoryDescriptor
        self.directorySource = directorySource
    }
    
    @MainActor
    private func stopObserving() throws {
        guard directoryDescriptor != nil else {
            assert(directorySource == nil)
            
            return
        }
        
        try directoryDescriptor?.closeAfter {
            directorySource?.cancel()
        }
    }
    
    @MainActor
    private func populateChildren() {
        do {
            children = try FileManager.default.suburls(at: self.url)
        } catch {
            logger.error(error)
            
            children = []
        }
    }
}
