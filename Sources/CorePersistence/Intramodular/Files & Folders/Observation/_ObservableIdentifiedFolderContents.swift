//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

public enum _ObservableIdentifiedFolderContentsElement<Item> {
    case url(any _FileOrFolderRepresenting)
    case inMemory(Item)
}

public protocol _ObservableIdentifiedFolderContentsType {
    associatedtype Item
    associatedtype ID: Hashable
    associatedtype WrappedValue
    
    typealias Element = _ObservableIdentifiedFolderContentsElement<Item>
    
    var cocoaFileManager: FileManager { get }
    var folder: any _FileOrFolderRepresenting { get }
    var fileConfiguration: (Element) throws -> _RelativeFileConfiguration<Item> { get }
    var id: (Item) -> ID { get }
    
    var _wrappedValue: WrappedValue { get set }
    var wrappedValue: WrappedValue { get set }
}

public protocol _ObservableIdentifiedFolderContentsUpdating<WrappedValue> {
    associatedtype WrappedValue
    associatedtype FolderContentsType: _ObservableIdentifiedFolderContentsType
    
    @MainActor
    static func initializePlaceholder(
        for parent: FolderContentsType
    ) throws -> WrappedValue
    
    @MainActor
    static func initialize(
        from directory: URL,
        for parent: FolderContentsType
    ) throws -> WrappedValue
    
    @MainActor
    static func update(
        from oldValue: WrappedValue,
        to newValue: WrappedValue,
        directory: URL,
        for parent: FolderContentsType
    ) throws
}

public final class _ObservableIdentifiedFolderContents<Item, ID: Hashable, WrappedValue>: _ObservableIdentifiedFolderContentsType, MutablePropertyWrapper, ObservableObject {
    public typealias Element = _ObservableIdentifiedFolderContentsElement<Item>
    
    public let cocoaFileManager = FileManager.default
    public let folder: any _FileOrFolderRepresenting
    public let fileConfiguration: (Element) throws -> _RelativeFileConfiguration<Item>
    public let id: (Item) -> ID
    
    var storage: [ID: _FileStorageCoordinators.RegularFile<MutableValueBox<Item>, Item>] = [:]
    
    public private(set) var _resolvedWrappedValue: WrappedValue?
    
    public var _ObservableIdentifiedFolderContentsUpdating_WrappedValue: any _ObservableIdentifiedFolderContentsUpdating.Type {
        if let wrappedValueType = WrappedValue.self as? any _IdentifierIndexingArrayOf_Protocol.Type {
            return try! wrappedValueType.folderContentsUpdating(forType: WrappedValue.self)
        } else {
            fatalError()
        }
    }
    
    @MainActor
    public var _wrappedValue: WrappedValue {
        get {
            guard let result = _resolvedWrappedValue else {
                self._resolvedWrappedValue = try! _ObservableIdentifiedFolderContentsUpdating_WrappedValue._opaque_initializePlaceholder(for: self, as: WrappedValue.self)
                
                _initializeResolvedWrappedValue()
                
                return _resolvedWrappedValue!
            }
            
            return result
        } set {
            assert(_resolvedWrappedValue != nil)
            
            _resolvedWrappedValue = newValue
        }
    }
    
    @MainActor
    public var folderURL: URL {
        get throws {
            try self.folder._toURL()
        }
    }
    
    @MainActor
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            objectWillChange.send()
            
            try! cocoaFileManager.withUserGrantedAccess(to: folderURL) { folderURL in
                try! _ObservableIdentifiedFolderContentsUpdating_WrappedValue._opaque_update(
                    from: _wrappedValue,
                    to: newValue,
                    directory: folderURL,
                    for: self
                )
            }
        }
    }
    
    @MainActor
    package init(
        folder: any _FileOrFolderRepresenting,
        fileConfiguration: @escaping (Element) throws -> _RelativeFileConfiguration<Item>,
        id: @escaping (Item) -> ID
    ) {
        self.folder = folder
        self.fileConfiguration = fileConfiguration
        self.id = id
    }
    
    @MainActor
    private func _initializeResolvedWrappedValue() {
        _expectNoThrow {
            let folderURL = try self.folderURL
            
            do {
                if !cocoaFileManager.fileExists(at: folderURL) {
                    try cocoaFileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
                }
            } catch {
                runtimeIssue(error)
            }
            
            try cocoaFileManager.withUserGrantedAccess(to: folderURL) { url in
                self._resolvedWrappedValue = .init(try _ObservableIdentifiedFolderContentsUpdating_WrappedValue._opaque_initialize(from: url, for: self))
            }
        }
    }
}

extension _IdentifierIndexingArrayOf_Protocol {
    public static func folderContentsUpdating<T>(
        forType type: T.Type
    ) throws -> any _ObservableIdentifiedFolderContentsUpdating.Type {
        try cast(_ObservableIdentifiedFolderContentsUpdatingTypes._IdentifierIndexingArray<Element, ID>.self)
    }
}

public enum _ObservableIdentifiedFolderContentsUpdatingTypes {
    
}

extension _ObservableIdentifiedFolderContentsUpdatingTypes {
    public struct _IdentifierIndexingArray<Item, ID: Hashable>: _ObservableIdentifiedFolderContentsUpdating {
        public typealias WrappedValue = IdentifierIndexingArray<Item, ID>
        public typealias FolderContentsType = _ObservableIdentifiedFolderContents<Item, ID, IdentifierIndexingArray<Item, ID>>
        
        public static func initializePlaceholder(
            for parent: _ObservableIdentifiedFolderContents<Item, ID, IdentifierIndexingArray<Item, ID>>
        ) throws -> IdentifierIndexingArray<Item, ID> {
            IdentifierIndexingArray(id: parent.id)
        }
        
        @MainActor
        public static func initialize(
            from directory: URL,
            for parent: FolderContentsType
        ) throws -> WrappedValue {
            var result = WrappedValue(id: parent.id)
            
            try parent.cocoaFileManager.createDirectoryIfNecessary(at: directory, withIntermediateDirectories: true)
            
            let urls = try parent.cocoaFileManager.contentsOfDirectory(at: directory)
            
            for url in urls {
                guard !parent.cocoaFileManager.isDirectory(at: url) else {
                    continue
                }
                
                if let filename = url._fileNameWithExtension {
                    guard !parent.cocoaFileManager._practicallyIgnoredFilenames.contains(filename) else {
                        continue
                    }
                }
                
                var fileConfiguration = try parent.fileConfiguration(.url(FileURL(url)))
                let relativeFilePath = try fileConfiguration.consumePath()
                let fileURL = try FileURL(parent.folder._toURL().appendingPathComponent(relativeFilePath))
                
                let fileCoordinator = try _FileStorageCoordinators.RegularFile<MutableValueBox<Item>, Item>(
                    fileSystemResource: fileURL,
                    configuration: fileConfiguration
                )
                
                _expectNoThrow {
                    try _withLogicalParent(ofType: AnyObject.self) {
                        fileCoordinator._enclosingInstance = $0
                    }
                }
                
                let element = try fileCoordinator._wrappedValue
                
                parent.storage[parent.id(element)] = fileCoordinator
                
                result.append(element)
            }
            
            return result
        }
        
        @MainActor
        public static func update(
            from oldValue: WrappedValue,
            to newValue: WrappedValue,
            directory: URL,
            for parent: FolderContentsType
        ) throws {
            let difference = Set(newValue.identifiers).difference(from: Set(oldValue.identifiers))
            
            var removedKeysByValue: [_HashableOrObjectIdentifier: ID] = [:]
            var insertedKeysByValue: [_HashableOrObjectIdentifier: ID] = [:]
            var valuesInsertedMultipleTimes: Set<_HashableOrObjectIdentifier> = []
            
            for key in difference.removals {
                let _value = try oldValue[id: key].unwrap()
                
                if let value = _HashableOrObjectIdentifier(from: _value) {
                    removedKeysByValue[value] = key
                }
            }
            
            for key in difference.insertions {
                let _value = try newValue[id: key].unwrap()
                
                if let value = _HashableOrObjectIdentifier(from: _value) {
                    if insertedKeysByValue[value] != nil {
                        valuesInsertedMultipleTimes.insert(value)
                    }
                    
                    insertedKeysByValue[value] = key
                }
            }
            
            for value in valuesInsertedMultipleTimes {
                insertedKeysByValue[value] = nil
            }
            
            var renamedKeys: [ID: ID] = [:]
            
            for (value, removedKey) in removedKeysByValue {
                if let insertedKey = insertedKeysByValue[value] {
                    renamedKeys[removedKey] = insertedKey
                }
            }
            
            var updatedNewValue = oldValue
            
            for key in difference.removals {
                guard renamedKeys[key] == nil else {
                    continue
                }
                
                let fileURL = try parent.storage[key].unwrap().fileSystemResource._toURL()
                
                assert(parent.cocoaFileManager.regularFileExists(at: fileURL))
                
                parent.storage[key]?.discard()
                parent.storage[key] = nil
                
                updatedNewValue[id: key] = nil
                
                try parent.cocoaFileManager.removeItemIfNecessary(at: fileURL)
            }
            
            for key in difference.insertions {
                guard renamedKeys[key] == nil else {
                    fatalError(.unexpected)
                }
                
                let element = newValue[id: key]!
                var fileConfiguration = try parent.fileConfiguration(.inMemory(element))
                let relativeFilePath = try fileConfiguration.consumePath()
                let fileURL = directory.appendingPathComponent(relativeFilePath)
                
                fileConfiguration.serialization?.initialValue = .available(element)
                
                try parent.cocoaFileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                
                let fileCoordinator = try! _FileStorageCoordinators.RegularFile<MutableValueBox<Item>, Item>(
                    fileSystemResource: FileURL(fileURL),
                    configuration: fileConfiguration
                )
                
                fileCoordinator.commit()
                
                parent.storage[key] = fileCoordinator
                updatedNewValue[id: key] = element
            }
            
            let updated = updatedNewValue._unorderedIdentifiers.removing(contentsOf: difference.insertions)
            
            for identifier in updated {
                let updatedElement = newValue[id: identifier]!
                
                parent.storage[identifier]!.wrappedValue = updatedElement
                
                updatedNewValue[id: identifier] = updatedElement
            }
            
            parent._wrappedValue = updatedNewValue
        }
    }
}

// MARK: - Internal

extension _ObservableIdentifiedFolderContentsUpdating {
    @MainActor
    fileprivate static func _opaque_initializePlaceholder<T>(
        for parent: any _ObservableIdentifiedFolderContentsType,
        as: T.Type
    ) throws -> T {
        try cast(Self.initializePlaceholder(for: cast(parent)), to: T.self)
    }
    
    @MainActor
    fileprivate static func _opaque_initialize<T>(
        from directory: URL,
        for parent: any _ObservableIdentifiedFolderContentsType
    ) throws -> T {
        try cast(Self.initialize(from: directory, for: cast(parent)), to: T.self)
    }
    
    @MainActor
    fileprivate static func _opaque_update<T>(
        from oldValue: T,
        to newValue: T,
        directory: URL,
        for parent: any _ObservableIdentifiedFolderContentsType
    ) throws {
        try update(
            from: oldValue as! WrappedValue,
            to: newValue as! WrappedValue,
            directory: directory,
            for: parent as! FolderContentsType
        )
    }
}
