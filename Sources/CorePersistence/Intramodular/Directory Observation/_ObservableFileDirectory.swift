//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import FoundationX
import System
import Swallow

public protocol _ObservableFileDirectoryType: Logging, ObservableObject {
    var cocoaFileManager: FileManager { get }
}

open class _ObservableFileDirectory: _ObservableFileDirectoryType {
    public let url: URL
    public let cocoaFileManager: FileManager
    
    private var observation: DispatchSourceFileSystemObjectObservation?
    
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
                return try expression.keyPath._accessValue(of: self, as: Array<any URLConvertible>.self).map({ $0.url }) as! TargetType
            }
        }
        
        TODO.unimplemented
    }
    
    @MainActor
    private func beginObserving() throws {
        try stopObserving()
        
        observation = try DispatchSourceFileSystemObjectObservation(
            filePath: url.path,
            onEvent: { [weak self] _ in
                Task { @MainActor in
                    self?.objectWillChange.send()
                }
            }
        )
    }
    
    @MainActor
    private func stopObserving() throws {
        observation = nil
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
