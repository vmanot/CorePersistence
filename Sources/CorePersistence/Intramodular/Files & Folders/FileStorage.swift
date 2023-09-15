//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge
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
public final class FileStorage<Value> {
    public struct Options: Codable, ExpressibleByNilLiteral, Hashable {
        public var readErrorRecoveryStrategy: ReadErrorRecoveryStrategy
        
        public init(
            readErrorRecoveryStrategy: ReadErrorRecoveryStrategy
        ) {
            self.readErrorRecoveryStrategy = readErrorRecoveryStrategy
        }
        
        public init(nilLiteral: ()) {
            self.readErrorRecoveryStrategy = .fatalError
        }
    }
    
    private let coordinator: Coordinator
    private var objectWillChangeConduit: AnyCancellable?
    
    public var wrappedValue: Value {
        get {
            coordinator.value
        } set {
            coordinator.value = newValue
        }
    }
    
    public var projectedValue: FileStorage {
        self
    }
    
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, FileStorage>
    ) -> Value where EnclosingSelf.ObjectWillChangePublisher: _opaque_VoidSender {
        get {
            object[keyPath: storageKeyPath].setUpObjectWillChangeConduitIfNecessary(_enclosingInstance: object)
            
            return object[keyPath: storageKeyPath].wrappedValue
        } set {
            object[keyPath: storageKeyPath].setUpObjectWillChangeConduitIfNecessary(_enclosingInstance: object)
            
            object.objectWillChange.send()
            
            object[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
    
    private func setUpObjectWillChangeConduitIfNecessary<EnclosingSelf: ObservableObject>(
        _enclosingInstance object: EnclosingSelf
    ) {
        guard objectWillChangeConduit == nil else {
            return
        }
        
        if let objectWillChange = object.objectWillChange as? _opaque_VoidSender {
            objectWillChangeConduit = coordinator.objectWillChange
                .publish(to: objectWillChange)
                .sink()
        } else {
            assertionFailure()
        }
    }
    
    // MARK: - Initializers
    
    init(coordinator: FileStorage.Coordinator) {
        self.coordinator = coordinator
    }
    
    public convenience init(
        wrappedValue: Value,
        _ location: CanonicalFileDirectory,
        path: String,
        options: FileStorage.Options
    ) where Value: DataCodableWithDefaultStrategies {
        let url = try! FileURL(location.toURL().appendingPathComponent(path, isDirectory: false))
        
        self.init(
            coordinator: .init(
                initialValue: wrappedValue,
                file: url,
                coder: .init(
                    .dataCodableType(
                        Value.self,
                        strategy: (
                            decoding: Value.defaultDataDecodingStrategy,
                            encoding: Value.defaultDataEncodingStrategy
                        )
                    )
                ),
                options: options
            )
        )
    }
    
    public init<Coder: TopLevelDataCoder>(
        wrappedValue: Value,
        location: URL,
        coder: Coder,
        options: FileStorage.Options
    ) where Value: Codable {
        let directoryURL = location.deletingLastPathComponent()
        let url = FileURL(location)
        
        try! FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        assert(FileManager.default.directoryExists(at: directoryURL))
        
        self.coordinator = .init(
            initialValue: wrappedValue,
            file: url,
            coder: .init(.topLevelDataCoder(coder, forType: Value.self)),
            options: options
        )
    }
    
    public convenience init<Coder: TopLevelDataCoder>(
        wrappedValue: Value,
        location: () -> URL,
        coder: Coder,
        options: FileStorage.Options
    ) where Value: Codable {
        let url = FileURL(location())
        
        self.init(
            coordinator: .init(
                initialValue: wrappedValue,
                file: url,
                coder: .init(.topLevelDataCoder(coder, forType: Value.self)),
                options: options
            )
        )
    }
    
    public convenience init<Coder: TopLevelDataCoder>(
        wrappedValue: Value,
        _ location: CanonicalFileDirectory,
        path: String,
        coder: Coder,
        options: FileStorage.Options
    ) where Value: Codable {
        self.init(
            wrappedValue: wrappedValue,
            location: try! location.toURL().appendingPathComponent(path, isDirectory: false),
            coder: coder,
            options: options
        )
    }
    
    public convenience init<Coder: TopLevelDataCoder>(
        _ location: CanonicalFileDirectory,
        path: String,
        coder: Coder,
        options: FileStorage.Options
    ) where Value: Codable & Initiable {
        self.init(
            wrappedValue: .init(),
            location: try! location.toURL().appendingPathComponent(path, isDirectory: false),
            coder: coder,
            options: options
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
    public typealias Output = Value
    public typealias Failure = Never
    
    public func receive<S: Subscriber<Value, Never>>(subscriber: S) {
        coordinator.objectWillChange
            .compactMap({ [weak coordinator] in coordinator?.value })
            .receive(subscriber: subscriber)
    }
}

// MARK: - Auxiliary

extension FileStorage {
    public typealias ReadErrorRecoveryStrategy = _FileStorageReadErrorRecoveryStrategy
}
