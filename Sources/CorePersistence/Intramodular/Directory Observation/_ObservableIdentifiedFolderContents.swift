//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

public struct _ObservableIdentifiedFolderContentsElement<Item, ID: Hashable> {
    public enum Value {
        case url(any _FileOrFolderRepresenting)
        case inMemory(Item)
    }
    
    public var value: Value
    public var id: ID?
    
    public init(value: Value, id: ID?) {
        self.value = value
        self.id = id
        
        #try(.optimistic) {
            if id == nil, case .url(let url) = value, ID.self == URL.self {
                self.id = try cast(url._toURL())
            }
        }
    }
    
    public init(value: Item, id: ID?) {
        self.init(value: .inMemory(value), id: id)
    }
    
    public init(url: any _FileOrFolderRepresenting, id: ID?) {
        self.init(value: .url(url), id: id)
    }
}

public protocol _ObservableIdentifiedFolderContentsType {
    associatedtype Item
    associatedtype ID: Hashable
    associatedtype WrappedValue
    
    typealias Element = _ObservableIdentifiedFolderContentsElement<Item, ID>
    
    var cocoaFileManager: FileManager { get }
    var folder: any _FileOrFolderRepresenting { get }
    var fileConfiguration: (Element) throws -> _RelativeFileConfiguration<Item> { get }
    var id: ((Item) -> ID)? { get }
    
    var _wrappedValue: WrappedValue { get set }
    var wrappedValue: WrappedValue { get set }
}

public final class _ObservableIdentifiedFolderContents<Item, ID: Hashable, WrappedValue>: _ObservableIdentifiedFolderContentsType, MutablePropertyWrapper, _ObservableObjectX {
    public typealias Element = _ObservableIdentifiedFolderContentsElement<Item, ID>
    
    public let _objectWillChange = ObservableObjectPublisher()
    
    public lazy var objectWillChange = AnyObjectWillChangePublisher(from: _objectWillChange)
    
    public let cocoaFileManager = FileManager.default
    public let folder: any _FileOrFolderRepresenting
    public let fileConfiguration: (Element) throws -> _RelativeFileConfiguration<Item>
    public let id: ((Item) -> ID)?
    
    var storage: [ID: _FileStorageCoordinators.RegularFile<MutableValueBox<Item>, Item>] = [:]
    
    public private(set) var _resolvedWrappedValue: WrappedValue?
    
    public var _ObservableIdentifiedFolderContentsUpdating_WrappedValue: any _ObservableIdentifiedFolderContentsUpdating.Type {
        if let wrappedValueType = WrappedValue.self as? any _IdentifierIndexingArrayOf_Protocol.Type {
            return try! wrappedValueType.folderContentsUpdating(forType: WrappedValue.self)
        } else if let wrappedValueType = WrappedValue.self as? any DictionaryProtocol.Type {
            return try! wrappedValueType.folderContentsUpdating(forType: WrappedValue.self)
        } else {
            fatalError()
        }
    }
    
    public var _wrappedValue: WrappedValue {
        get {
            guard let result = _resolvedWrappedValue else {
                _revertFromDisk()
                
                guard let _resolvedWrappedValue else {
                    let placeholder: WrappedValue = try! _ObservableIdentifiedFolderContentsUpdating_WrappedValue._opaque_initializePlaceholder(
                        for: self,
                        as: WrappedValue.self
                    )
                    
                    return placeholder
                }
                
                return _resolvedWrappedValue
            }
            
            return result
        } set {
            if let _resolvedWrappedValue {
                if AnyEquatable.equate(newValue, _resolvedWrappedValue) == true {
                    return
                }
            }
            
            _objectWillChange.send()
            
            assert(_resolvedWrappedValue != nil)
            
            _resolvedWrappedValue = newValue
            
            objectDidChange.send()
        }
    }
    
    public var directoryURL: URL {
        get throws {
            try self.folder._toURL()
        }
    }
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            do {
                try observation.disableAndPerform {
                    try _writeToDisk(newValue: newValue)
                }
                
                self._resolvedWrappedValue = newValue
            } catch {
                runtimeIssue(error)
            }
        }
    }
    
    private var observation: _DirectoryEventObservation!
    
    package init(
        folder: any _FileOrFolderRepresenting,
        fileConfiguration: @escaping (Element) throws -> _RelativeFileConfiguration<Item>,
        id: ((Item) -> ID)?
    ) {
        self.folder = folder
        self.fileConfiguration = fileConfiguration
        self.id = id
        
        #try(.optimistic) {
            try _setUpDiskObserver()
        }
    }
    
    private func _writeToDisk(newValue: WrappedValue) throws {
        return try MainActor.assumeIsolated {
            try cocoaFileManager.withUserGrantedAccess(to: directoryURL) { directoryURL in
                try _ObservableIdentifiedFolderContentsUpdating_WrappedValue._opaque_update(
                    from: _wrappedValue,
                    to: newValue,
                    directory: directoryURL,
                    for: self
                )
            }
        }
    }
    
    private func _revertFromDisk() {
        #try(.optimistic) {
            let value: WrappedValue = try _readFromDisk()
            
            self._resolvedWrappedValue = value
        }
    }
    
    private func _setUpDiskObserver() throws {
        observation = _DirectoryEventObserver.shared.observe(directory: try directoryURL) { [weak self] events in
            guard let `self` = self else {
                return
            }
            
            _ = self
            
            /*Task.detached { @MainActor in
             if events.contains(where: \.eventType.isModificationOrDeletion) {
             guard self._resolvedWrappedValue != nil else {
             return
             }
             
             try await self.observation.disableAndPerform {
             self.objectWillChange?.send()
             self._resetImmediately()
             self._revertFromDisk()
             }
             }
             }*/
        }
    }
    
    private func _resetImmediately() {
        self.objectWillChange.send()
        self.storage = [:]
        self._resolvedWrappedValue = nil
    }
    
    private func _readFromDisk() throws -> WrappedValue {
        let directoryURL: URL = try self.directoryURL
        
        do {
            if !cocoaFileManager.fileExists(at: directoryURL) {
                try cocoaFileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            }
        } catch {
            runtimeIssue(error)
        }
        
        return try MainActor.assumeIsolated {
            return try cocoaFileManager.withUserGrantedAccess(to: directoryURL) { (url: URL) -> WrappedValue in
                let wrappedValue: WrappedValue = try _ObservableIdentifiedFolderContentsUpdating_WrappedValue._opaque_initialize(from: url, for: self)
                
                return wrappedValue
            }
        }
    }
}

// MARK: - Internal

extension _ObservableIdentifiedFolderContentsUpdating {
    fileprivate static func _opaque_initializePlaceholder<T>(
        for parent: any _ObservableIdentifiedFolderContentsType,
        as: T.Type
    ) throws -> T {
        try cast(Self.initializePlaceholder(for: cast(parent)), to: T.self)
    }
    
    fileprivate static func _opaque_initialize<T>(
        from directory: URL,
        for parent: any _ObservableIdentifiedFolderContentsType
    ) throws -> T {
        try cast(Self.initialize(from: directory, for: cast(parent)), to: T.self)
    }
    
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

extension DictionaryProtocol {
    fileprivate static func folderContentsUpdating<T>(
        forType type: T.Type
    ) throws -> any _ObservableIdentifiedFolderContentsUpdating.Type {
        try cast(_ObservableIdentifiedFolderContentsUpdatingTypes._Dictionary<URL, DictionaryValue>.self)
    }
}
