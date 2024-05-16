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

extension _IdentifierIndexingArrayOf_Protocol {
    fileprivate static func folderContentsUpdating<T>(
        forType type: T.Type
    ) throws -> any _ObservableIdentifiedFolderContentsUpdating.Type {
        try cast(_ObservableIdentifiedFolderContentsUpdatingTypes._IdentifierIndexingArray<Element, ID>.self)
    }
}
