//
// Copyright (c) Vatsal Manot
//

import FoundationX
@_spi(Internal) import Merge
import Runtime
import Swallow

/// The strategy used to recover from a read error.
public enum _FileStorageReadErrorRecoveryStrategy: String, Codable, Hashable, Sendable {
    /// Halt the execution of the app.
    case fatalError
    /// Discard existing data (if any) and reset with the initial value.
    case discardAndReset
}

/// A property wrapper type that reflects data stored in a file on the disk.
///
/// The initial read is done asynchronously if possible, synchronously if the `wrappedValue` is accessed before the background read can complete.
///
/// Writing is done asynchronously on a high-priority background thread, and synchronously on the deinitialization of the internal storage of this property wrapper.
@propertyWrapper
public final class FileStorage<ValueType, UnwrappedType>: Logging {
    public typealias Coordinator = _AnyFileStorageCoordinator<ValueType, UnwrappedType>
    
    private var makeCoordinator: () throws -> Coordinator
    private lazy var coordinator: Coordinator = {
        try! makeCoordinator()
    }()
    private var objectWillChangeConduit: AnyCancellable?
    
    public var wrappedValue: UnwrappedType {
        get {
            coordinator.wrappedValue
        } set {
            coordinator.wrappedValue = newValue
        }
    }
    
    public var projectedValue: FileStorage {
        self
    }
    
    public var url: URL {
        get throws {
            try coordinator.fileSystemResource._toURL()
        }
    }
    
    public func setLocation(
        _ url: URL
    ) throws {
        if Thread.isMainThread {
            try MainActor.unsafeAssumeIsolated {
                try FileManager.default.withUserGrantedAccess(to: url) { url in
                    coordinator.setFileSystemResource(AnyFileURL(url))
                }
            }
        } else {
            coordinator.setFileSystemResource(AnyFileURL(url))
        }
    }
    
    public func setLocation(_ directory: CanonicalFileDirectory, path: String) throws {
        try setLocation(directory.toURL().appending(URL.PathComponent(path)))
    }
    
    @MainActor
    public static subscript<EnclosingSelf>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, UnwrappedType>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, FileStorage>
    ) -> UnwrappedType {
        get {
            instance[keyPath: storageKeyPath]._setUpEnclosingInstance(instance)
            
            return instance[keyPath: storageKeyPath].wrappedValue
        } set {
            instance[keyPath: storageKeyPath]._setUpEnclosingInstance(instance)
            
            _ObservableObject_objectWillChange_send(instance)
            
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
    
    fileprivate func _setUpEnclosingInstance<EnclosingSelf>(
        _ object: EnclosingSelf
    ) {
        guard let object = (object as? any ObservableObject) else {
            return
        }
        
        defer {
            self.coordinator._enclosingInstance = object
        }
        
        guard objectWillChangeConduit == nil else {
            return
        }
        
        if let objectWillChange = (object.objectWillChange as any Publisher) as? _opaque_VoidSender {
            objectWillChangeConduit = coordinator.objectWillChange
                .publish(to: objectWillChange)
                .sink()
        } else {
            assertionFailure()
        }
    }
    
    init(
        coordinator: @autoclosure @escaping () throws -> FileStorage.Coordinator
    ) {
        self.makeCoordinator = coordinator
    }
}

// MARK: - Extensions

extension FileStorage {
    public func commit() {
        coordinator.commit()
    }
    
    public func commitUnconditionally() {
        coordinator.commitUnconditionally()
    }
}

// MARK: - Conformances

extension FileStorage: ObjectDidChangeObservableObject {
    public var objectWillChange: AnyObjectWillChangePublisher {
        coordinator.eraseObjectWillChangePublisher()
    }
    
    public var objectDidChange: _ObjectDidChangePublisher {
        coordinator.objectDidChange
    }
}

extension FileStorage: Publisher {
    public typealias Output = UnwrappedType
    public typealias Failure = Never
    
    public func receive<S: Subscriber<UnwrappedType, Never>>(subscriber: S) {
        coordinator
            .objectDidChange
            .compactMap({ [weak coordinator] in coordinator?.wrappedValue })
            .receive(subscriber: subscriber)
    }
}

extension FileStorage: _FileOrFolderRepresenting {
    public func withResolvedURL<R>(
        perform operation: (URL) throws -> R
    ) throws -> R {
        try self.coordinator.fileSystemResource.withResolvedURL { (url: URL) in
            try operation(url)
        }
    }

    public func _toURL() throws -> URL {
        try self.coordinator.fileSystemResource._toURL()
    }
    
    public func encode<T>(
        _ contents: T,
        using coder: some _TopLevelFileDecoderEncoder
    ) throws {
        throw Never.Reason.illegal
    }
    
    public func child(
        at path: URL.RelativePath
    ) throws -> FilesystemChild {
        throw Never.Reason.illegal
    }
}

extension FileStorage: Equatable where UnwrappedType: Equatable {
    public static func == (lhs: FileStorage, rhs: FileStorage) -> Bool {
        do {
            return (try lhs.url) == (try rhs.url) && lhs.coordinator.wrappedValue == rhs.coordinator.wrappedValue
        } catch {
            runtimeIssue(error)
            
            return false
        }
    }
}

extension FileStorage: Hashable where UnwrappedType: Hashable {
    public func hash(into hasher: inout Hasher) {
        MainActor.unsafeAssumeIsolated {
            do {
                try hasher.combine(url)
            } catch {
                runtimeIssue(error)
            }
            
            hasher.combine(wrappedValue)
        }
    }
}

// MARK: - Auxiliary

extension FileStorage {
    public typealias ReadErrorRecoveryStrategy = _FileStorageReadErrorRecoveryStrategy
}

public struct FileStorageOptions: Codable, ExpressibleByNilLiteral, Hashable {
    public typealias ReadErrorRecoveryStrategy = _FileStorageReadErrorRecoveryStrategy
    
    public var readErrorRecoveryStrategy: ReadErrorRecoveryStrategy?
    
    public init(
        readErrorRecoveryStrategy: ReadErrorRecoveryStrategy?
    ) {
        self.readErrorRecoveryStrategy = readErrorRecoveryStrategy
    }
    
    public init(nilLiteral: ()) {
        self.readErrorRecoveryStrategy = nil
    }
}
