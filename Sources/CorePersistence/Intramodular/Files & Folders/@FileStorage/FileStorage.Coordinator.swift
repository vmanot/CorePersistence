//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

/// A namespace for @FileStorage coordinator implementations.
public enum _FileStorageCoordinators: _StaticNamespaceType {
    
}

public class _AnyFileStorageCoordinator<ValueType, UnwrappedValue>: ObservableObject, @unchecked Sendable {
    enum StateFlag {
        case initialReadComplete
        case latestWritten
    }
    
    weak var _enclosingInstance: AnyObject?
    
    let cancellables = Cancellables()
    let lock = OSUnfairLock()
    
    let writeQueue = DispatchQueue(
        label: "com.vmanot.Data.FileStorage.Coordinator.write",
        qos: .default
    )
    
    var fileSystemResource: any _FileOrFolderRepresenting
    let configuration: _RelativeFileConfiguration<UnwrappedValue>
    
    @MainActor(unsafe)
    open var wrappedValue: UnwrappedValue {
        get {
            fatalError(.abstract)
        } set {
            fatalError(.abstract)
        }
    }
    
    @MainActor
    init(
        fileSystemResource: any _FileOrFolderRepresenting,
        configuration: _RelativeFileConfiguration<UnwrappedValue>
    ) throws {
        self.fileSystemResource = fileSystemResource
        self.configuration = configuration
    }
    
    open func commit() {
        fatalError(.abstract)
    }
    
    deinit {
        commit()
    }
}

// MARK: - Initializers

extension _FileStorageCoordinators.RegularFile {
    @MainActor
    convenience init(
        initialValue: UnwrappedValue?,
        file: any _FileOrFolderRepresenting,
        coder: _AnyConfiguredFileCoder,
        options: FileStorageOptions
    ) throws {
        try self.init(
            fileSystemResource: file,
            configuration: try! _RelativeFileConfiguration(
                path: nil,
                coder: coder,
                readWriteOptions: options,
                initialValue: initialValue
            ),
            cache: InMemorySingleValueCache()
        )
    }
}
