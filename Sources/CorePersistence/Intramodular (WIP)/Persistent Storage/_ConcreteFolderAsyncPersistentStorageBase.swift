//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
internal import OrderedCollections
import Swallow

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class _ConcreteFolderAsyncPersistentStorageBase<Resource: _AsyncPersistentResourceCoordinator>: _AsyncPersistentStorageBase {
    public typealias WrappedValue = [Resource.Value]
    public typealias ProjectedValue = [Resource.Value]
    public typealias ResourceAccessor = (any _FileOrFolderRepresenting) async throws -> Resource?
    
    private let directory: any _FileOrFolderRepresenting
    private let resource: (any _FileOrFolderRepresenting) async throws -> Resource?
    
    private var base: _SyncedAsyncPersistentResources<AnyAsyncSequence<Resource>>
    
    public var objectWillChange: ObservableObjectPublisher {
        base.objectWillChange
    }
    
    public var wrappedValue: WrappedValue {
        Array(base._cachedOrSynchronousSnapshot.values)
    }
    
    public var projectedValue: ProjectedValue {
        wrappedValue
    }
    
    init(
        directory: any _FileOrFolderRepresenting,
        resource: @escaping ResourceAccessor
    ) throws {
        #try(.optimistic) {
            try FileManager.default.createDirectory(at: directory._toURL(), withIntermediateDirectories: true)
        }
        
        self.directory = directory
        self.resource = resource
        
        self.base = .init(
            stream: try directory._opaque_observeFilesystemChildrenAsynchronously().map {
                $0.compactMap {
                    guard let element = try await resource($0) else {
                        return nil
                    }
                    
                    return element
                }
                .eraseToAnyAsyncSequence()
            }
        )
    }
    
    convenience init(
        directory: URL,
        resource: @escaping ResourceAccessor
    ) throws {
        try self.init(
            directory: AnyFileURL(directory),
            resource: resource
        )
    }
}

public class _AsyncFileResourceCoordinator<Value>: _MutableAsyncPersistentResourceCoordinator {
    private let lock = OSUnfairLock()
    
    var file: any _FileOrFolderRepresenting
    
    let coder: any _TopLevelFileDecoderEncoder
    
    public var id: AnyHashable {
        file.id.erasedAsAnyHashable
    }
    
    init(file: any _FileOrFolderRepresenting, coder: any _TopLevelFileDecoderEncoder) {
        self.file = file
        self.coder = coder
    }
    
    public func get() async throws -> Value {
        try await Task(priority: .high) {
            try _getSynchronously()
        }
        .value
    }
    
    public func _getSynchronously() throws -> Value {
        try file.decode(Value.self, using: coder).unwrap()
    }
    
    public func update(
        _ resource: Value
    ) async throws {
        try await Task {
            try file.encode(resource, using: coder)
        }
        .value
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension _ConcreteFolderAsyncPersistentStorageBase {
    public final class Projection {
        
    }
}
