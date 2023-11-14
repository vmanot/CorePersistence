//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

public enum FolderStorageElement<Item> {
    case url(any _FileOrFolderRepresenting)
    case inMemory(Item)
}

public final class FolderContents<Item, ID: Hashable>: MutablePropertyWrapper, ObservableObject {
    public typealias WrappedValue = IdentifierIndexingArray<Item, ID>
    
    public let folder: any _FileOrFolderRepresenting
    public let fileConfiguration: (FolderStorageElement<Item>) throws -> _RelativeFileConfiguration<Item>
    public let id: (Item) -> ID
    
    private var storage: [ID: _NaiveFileStorageCoordinator<MutableValueBox<Item>, Item>] = [:]
    
    public private(set) var _wrappedValue: WrappedValue
    
    public var folderURL: URL {
        get throws {
            try self.folder._toURL()
        }
    }
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            objectWillChange.send()
            
            try! setNewValue(newValue)
        }
    }
    
    public init(
        folder: any _FileOrFolderRepresenting,
        fileConfiguration: @escaping (FolderStorageElement<Item>) throws -> _RelativeFileConfiguration<Item>,
        id: @escaping (Item) -> ID
    ) {
        self.folder = folder
        self.fileConfiguration = fileConfiguration
        self.id = id
        self._wrappedValue = .init(id: id)
        
        initialize()
    }
    
    func initialize() {
        let urls = _expectNoThrow {
            try FileManager.default.contentsOfDirectory(at: try folderURL)
        } ?? []
        
        for url in urls {
            _expectNoThrow {
                var fileConfiguration = try self.fileConfiguration(.url(url.toFileURL()))
                let relativeFilePath = try fileConfiguration.consumePath()
                let fileURL = try folder._toURL().appendingPathComponent(relativeFilePath).toFileURL()
                
                let fileCoordinator = try _NaiveFileStorageCoordinator<MutableValueBox<Item>, Item>(
                    fileSystemResource: fileURL,
                    configuration: fileConfiguration
                )
                
                let element = try fileCoordinator._wrappedValue
                
                self.storage[self.id(element)] = fileCoordinator
                
                self._wrappedValue.append(element)
            }
        }
    }
    
    public func setNewValue(_ newValue: IdentifierIndexingArray<Item, ID>) throws {
        let oldValue = self._wrappedValue
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
            
            let child = try oldValue[id: key].unwrap()
            
            var fileConfiguration = try fileConfiguration(.inMemory(child))
            let relativeFilePath = try fileConfiguration.consumePath()
            let fileURL = try folder._toURL().appendingPathComponent(relativeFilePath)
            
            assert(FileManager.default.regularFileExists(at: fileURL))
            
            storage[key] = nil
            updatedNewValue[id: key] = nil
            
            try FileManager.default.removeItemIfNecessary(at: fileURL)
        }
        
        for key in difference.insertions {
            guard renamedKeys[key] == nil else {
                fatalError(.unexpected)
            }
            
            let element = newValue[id: key]!
            var fileConfiguration = try fileConfiguration(.inMemory(element))
            let relativeFilePath = try fileConfiguration.consumePath()
            let fileURL = try folderURL.appendingPathComponent(relativeFilePath)
            
            fileConfiguration.serialization.initialValue = .available(element)
            
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            let fileCoordinator = try! _NaiveFileStorageCoordinator<MutableValueBox<Item>, Item>(
                fileSystemResource: FileURL(fileURL),
                configuration: fileConfiguration
            )
            
            storage[key] = fileCoordinator
            updatedNewValue[id: key] = element
        }
        
        let updated = updatedNewValue._unorderedIdentifiers.removing(contentsOf: difference.insertions)
        
        for identifier in updated {
            self.storage[identifier]!.wrappedValue = newValue[id: identifier]!
        }
        
        self._wrappedValue = updatedNewValue
    }
}

