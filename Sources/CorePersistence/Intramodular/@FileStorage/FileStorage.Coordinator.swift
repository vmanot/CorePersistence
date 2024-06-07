//
// Copyright (c) Vatsal Manot
//

import FoundationX
@_spi(Internal) import Merge
import Swallow

/// A namespace for @FileStorage coordinator implementations.
public enum _FileStorageCoordinators: _StaticSwift.Namespace {
    
}

public class _AnyFileStorageCoordinator<ValueType, UnwrappedValue>: _ObservableObjectX, @unchecked Sendable {
    public enum StateFlag {
        case initialReadComplete
        case latestWritten
        case discarded
    }
    
    weak var _enclosingInstance: AnyObject? {
        didSet {
            guard !(_enclosingInstance === oldValue) else {
                return
            }
            
            if let _enclosingInstance = _enclosingInstance as? (any PersistenceRepresentable) {
                _persistenceContext.persistenceRepresentationResolutionContext.sourceList.insert(Weak(wrappedValue: _enclosingInstance))
            }
        }
    }
    
    lazy var _defaultObjectWillChangePublisher = ObservableObjectPublisher()
    lazy var _defaultObjectDidChangePublisher = _ObjectDidChangePublisher()
        
    let _persistenceContext = _PersistenceContext(for: ValueType.self)
    let cancellables = Cancellables()
    let lock = OSUnfairLock()
    
    var resolveFileSystemResource: () throws -> any _FileOrFolderRepresenting
    var configuration: _RelativeFileConfiguration<UnwrappedValue>

    public internal(set) var stateFlags: Set<StateFlag> = []
    
    let writeQueue = DispatchQueue(
        label: "com.vmanot.Data.FileStorage.Coordinator.write",
        qos: .default
    )
        
    open var objectWillChange: ObservableObjectPublisher {
        _defaultObjectWillChangePublisher
    }
    
    open var objectDidChange: _ObjectDidChangePublisher {
        _defaultObjectDidChangePublisher
    }

    var fileSystemResource: any _FileOrFolderRepresenting {
        get {
            try! resolveFileSystemResource()
        } set {
            resolveFileSystemResource = { newValue }
        }
    }
        
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
        fileSystemResource: @escaping () throws -> any _FileOrFolderRepresenting,
        configuration: _RelativeFileConfiguration<UnwrappedValue>
    ) throws {
        self.resolveFileSystemResource = fileSystemResource
        self.configuration = configuration
    }
    
    @MainActor
    init(
        fileSystemResource: @autoclosure @escaping () throws -> any _FileOrFolderRepresenting,
        configuration: _RelativeFileConfiguration<UnwrappedValue>
    ) throws {
        self.resolveFileSystemResource = fileSystemResource
        self.configuration = configuration
    }
    
    open func commit() {
        fatalError(.abstract)
    }
    
    open func discard() {
        guard !stateFlags.contains(.discarded) else {
            return
        }
        
        stateFlags.insert(.discarded)
    }
    
    deinit {
        guard !stateFlags.contains(.discarded) else {
            return
        }
        
        commit()
    }
}

// MARK: - Initializers

extension _FileStorageCoordinators.RegularFile {
    convenience init(
        initialValue: UnwrappedValue?,
        file: @autoclosure @escaping () throws -> any _FileOrFolderRepresenting,
        coder: (any _TopLevelFileDecoderEncoder),
        options: FileStorageOptions
    ) throws {
        try self.init(
            fileSystemResource: file(),
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
