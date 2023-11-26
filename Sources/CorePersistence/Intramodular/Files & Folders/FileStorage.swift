//
// Copyright (c) Vatsal Manot
//

import Foundation
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
public final class FileStorage<ValueType, UnwrappedType> {
    public typealias Coordinator = _AnyFileStorageCoordinator<ValueType, UnwrappedType>
    
    private let coordinator: Coordinator
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
    
    init(coordinator: FileStorage.Coordinator) {
        self.coordinator = coordinator
    }
}

// MARK: - Initializers

extension FileStorage {
    public convenience init<Coder: TopLevelDataCoder>(
        wrappedValue: UnwrappedType,
        location: () throws -> URL,
        coder: Coder,
        options: FileStorageOptions
    ) where UnwrappedType: Codable, ValueType == MutableValueBox<UnwrappedType> {
        self.init(
            coordinator: try! _NaiveFileStorageCoordinator(
                initialValue: wrappedValue,
                file: FileURL(location()),
                coder: .init(.topLevelDataCoder(coder, forType: UnwrappedType.self)),
                options: options
            )
        )
    }
    
    public convenience init<Coder: TopLevelDataCoder>(
        wrappedValue: UnwrappedType,
        location: URL,
        coder: Coder,
        options: FileStorageOptions
    ) where UnwrappedType: Codable, ValueType == MutableValueBox<UnwrappedType> {
        let directoryURL = location.deletingLastPathComponent()
        let url = FileURL(location)
        
        try! FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        assert(FileManager.default.directoryExists(at: directoryURL))
        
        self.init(
            coordinator: try! _NaiveFileStorageCoordinator(
                initialValue: wrappedValue,
                file: url,
                coder: .init(.topLevelDataCoder(coder, forType: UnwrappedType.self)),
                options: options
            )
        )
    }
    
    public convenience init<Coder: TopLevelDataCoder>(
        wrappedValue: UnwrappedType,
        _ location: CanonicalFileDirectory,
        path: String,
        coder: Coder,
        options: FileStorageOptions
    ) where UnwrappedType: Codable, ValueType == MutableValueBox<UnwrappedType> {
        self.init(
            wrappedValue: wrappedValue,
            location: try! location.toURL().appendingPathComponent(path, isDirectory: false),
            coder: coder,
            options: options
        )
    }
    
    public convenience init(
        wrappedValue: UnwrappedType,
        _ location: CanonicalFileDirectory,
        path: String,
        options: FileStorageOptions
    ) where UnwrappedType: DataCodableWithDefaultStrategies {
        let url = try! FileURL(location.toURL().appendingPathComponent(path, isDirectory: false))
        
        self.init(
            coordinator: try! _NaiveFileStorageCoordinator(
                initialValue: wrappedValue,
                file: url,
                coder: _AnyConfiguredFileCoder(
                    .dataCodableType(
                        UnwrappedType.self,
                        strategy: (
                            decoding: UnwrappedType.defaultDataDecodingStrategy,
                            encoding: UnwrappedType.defaultDataEncodingStrategy
                        )
                    )
                ),
                options: options
            )
        )
    }
    
    public convenience init<Coder: TopLevelDataCoder>(
        _ location: CanonicalFileDirectory,
        path: String,
        coder: Coder,
        options: FileStorageOptions
    ) where UnwrappedType: Codable & Initiable, ValueType == MutableValueBox<UnwrappedType> {
        self.init(
            wrappedValue: .init(),
            location: try! location.toURL().appendingPathComponent(path, isDirectory: false),
            coder: coder,
            options: options
        )
    }
}

@MainActor
extension FileStorage {
    public convenience init<Item, ID>(
        directory: () throws -> URL,
        file: @escaping (FolderStorageElement<Item>) -> _RelativeFileConfiguration<Item>,
        id: KeyPath<Item, ID>,
        options: FileStorageOptions = nil
    ) where ValueType == FolderContents<Item, ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            coordinator: try! FolderContents.FileStorageCoordinator(
                base: .init(
                    folder: try! directory().toFileURL(),
                    fileConfiguration: file,
                    id: { $0[keyPath: id] }
                )
            )
        )
    }
    
    public convenience init<Item, ID, Coder: TopLevelDataCoder>(
        directory: @escaping () throws -> URL,
        filename: @escaping (Item) -> FilenameProvider,
        coder: Coder,
        id: KeyPath<Item, ID>,
        options: FileStorageOptions = nil
    ) where Item: Codable, ValueType == FolderContents<Item, ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            coordinator: try! FolderContents.FileStorageCoordinator(
                base: .init(
                    folder: try! directory().toFileURL(),
                    fileConfiguration: { element in
                        switch element {
                            case .url(let fileURL):
                                try _RelativeFileConfiguration(
                                    fileURL: fileURL,
                                    coder: .init(coder, for: Item.self),
                                    readWriteOptions: options,
                                    initialValue: nil
                                )
                            case .inMemory(let element):
                                try _RelativeFileConfiguration(
                                    path: filename(element).filename(inDirectory: try directory()),
                                    coder: .init(coder, for: Item.self),
                                    readWriteOptions: options,
                                    initialValue: nil
                                )
                        }
                    },
                    id: { $0[keyPath: id] }
                )
            )
        )
    }
    
    public convenience init<Item, ID, Coder: TopLevelDataCoder>(
        directory: URL,
        filename: KeyPath<Item, FilenameProvider>,
        coder: Coder,
        id: KeyPath<Item, ID>,
        options: FileStorageOptions = nil
    ) where Item: Codable, ValueType == FolderContents<Item, ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            directory: { directory },
            filename: { $0[keyPath: filename] },
            coder: coder,
            id: id,
            options: options
        )
    }
    
    public convenience init<Item, ID, Filename: CustomFilenameConvertible & Randomnable, Coder: TopLevelDataCoder>(
        directory: URL,
        filename: Filename.Type,
        coder: Coder,
        id: KeyPath<Item, ID>,
        options: FileStorageOptions = nil
    ) where Item: Codable, ValueType == FolderContents<Item, ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            directory: { directory },
            filename: { _ in Filename.random().filenameProvider },
            coder: coder,
            id: id,
            options: options
        )
    }
    
    public convenience init<Item, Filename: CustomFilenameConvertible & Randomnable, Coder: TopLevelDataCoder>(
        directory: URL,
        filename: Filename.Type,
        coder: Coder,
        options: FileStorageOptions = nil
    ) where Item: Codable & Identifiable, ValueType == FolderContents<Item, Item.ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            directory: { directory },
            filename: { _ in Filename.random().filenameProvider },
            coder: coder,
            id: \.id,
            options: options
        )
    }
    
    public convenience init<Item, Filename: CustomFilenameConvertible & Randomnable, Coder: TopLevelDataCoder>(
        directory: CanonicalFileDirectory,
        path: String?,
        filename: Filename.Type,
        coder: Coder,
        options: FileStorageOptions = nil
    ) where Item: Codable & Identifiable, ValueType == FolderContents<Item, Item.ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            directory: { try directory.toURL().appendingDirectoryPathComponent(path) },
            filename: { _ in Filename.random().filenameProvider },
            coder: coder,
            id: \.id,
            options: options
        )
    }

    public convenience init<Item, ID, Coder: TopLevelDataCoder>(
        location: @escaping () throws -> URL,
        directory: String,
        coder: Coder,
        options: FileStorageOptions = nil
    ) where Item: Codable & Identifiable, Item.ID: CustomFilenameConvertible, ID == Item.ID, ValueType == FolderContents<Item, ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            directory: { try location().appendingPathComponent(directory) },
            filename: \.id.filenameProvider,
            coder: coder,
            id: \.id,
            options: options
        )
    }
    
    public convenience init<Item, ID, Coder: TopLevelDataCoder>(
        directory: @escaping () throws -> URL,
        coder: Coder,
        options: FileStorageOptions = nil
    ) where Item: Codable & PersistentIdentifierConvertible, Item.PersistentID: CustomFilenameConvertible, ID == Item.PersistentID, ValueType == FolderContents<Item, ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            directory: directory,
            filename: \.persistentID.filenameProvider,
            coder: coder,
            id: \.persistentID,
            options: options
        )
    }
    
    public convenience init<Item, ID, Coder: TopLevelDataCoder>(
        directory: @escaping () throws -> URL,
        coder: Coder,
        options: FileStorageOptions = nil
    ) where Item: Codable & Identifiable, Item.ID: CustomFilenameConvertible, ID == Item.ID, ValueType == FolderContents<Item, ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            directory: directory,
            filename: \.id.filenameProvider,
            coder: coder,
            id: \.id,
            options: options
        )
    }
    
    public convenience init<Item, ID, Coder: TopLevelDataCoder>(
        _ location: CanonicalFileDirectory,
        directory: String,
        coder: Coder,
        options: FileStorageOptions = nil
    ) where Item: Codable & Identifiable, Item.ID: CustomFilenameConvertible, ID == Item.ID, ValueType == FolderContents<Item, ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            directory: { try location.toURL().appendingPathComponent(directory, isDirectory: true) },
            filename: \.id.filenameProvider,
            coder: coder,
            id: \.id,
            options: options
        )
    }
    
    public convenience init<Item, ID>(
        _ location: CanonicalFileDirectory,
        directory: String,
        file: @escaping (FolderStorageElement<Item>) -> _RelativeFileConfiguration<Item>,
        id: KeyPath<Item, ID>
    ) where ValueType == FolderContents<Item, ID>, UnwrappedType == ValueType.WrappedValue {
        self.init(
            directory: {
                try location.toURL().appendingPathComponent(directory, isDirectory: true)
            },
            file: file,
            id: id
        )
    }
}

// MARK: - Extensions

extension FileStorage {
    public func commit() {
        coordinator.commit()
    }
}

// MARK: - Implemented Conformances

extension FileStorage: Publisher {
    public typealias Output = UnwrappedType
    public typealias Failure = Never
    
    public func receive<S: Subscriber<UnwrappedType, Never>>(subscriber: S) {
        coordinator.objectWillChange
            .compactMap({ [weak coordinator] in coordinator?.wrappedValue })
            .receive(subscriber: subscriber)
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
