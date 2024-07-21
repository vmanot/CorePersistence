//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import SwiftDI

public protocol _ObservableIdentifiedFolderContentsUpdating<WrappedValue> {
    associatedtype WrappedValue
    associatedtype FolderContentsType: _ObservableIdentifiedFolderContentsType
    
    static func initializePlaceholder(
        for parent: FolderContentsType
    ) throws -> WrappedValue
    
    static func initialize(
        from directory: URL,
        for parent: FolderContentsType
    ) throws -> WrappedValue
    
    static func update(
        from oldValue: WrappedValue,
        to newValue: WrappedValue,
        directory: URL,
        for parent: FolderContentsType
    ) throws
}

public enum _ObservableIdentifiedFolderContentsUpdatingTypes {
    
}

extension _ObservableIdentifiedFolderContentsUpdatingTypes {
    public struct _Dictionary<Key: Hashable, Value>: _ObservableIdentifiedFolderContentsUpdating {
        public typealias WrappedValue = Dictionary<Key, Value>
        public typealias FolderContentsType = _ObservableIdentifiedFolderContents<Value, Key, Dictionary<Key, Value>>
        
        public static func initializePlaceholder(
            for parent: FolderContentsType
        ) throws -> WrappedValue {
            [:]
        }
        
        @MainActor
        public static func initialize(
            from directory: URL,
            for parent: FolderContentsType
        ) throws -> WrappedValue {
            var result = WrappedValue()
            
            try parent.cocoaFileManager.createDirectoryIfNecessary(at: directory, withIntermediateDirectories: true)
            
            let urls: [URL] = try parent.cocoaFileManager.contentsOfDirectory(at: directory)
            
            for url in urls {
                do {
                    guard !parent.cocoaFileManager.isDirectory(at: url) else {
                        continue
                    }
                    
                    if let filename = url._fileNameWithExtension {
                        guard !parent.cocoaFileManager._practicallyIgnoredFilenames.contains(filename) else {
                            continue
                        }
                    }
                    
                    let element = _ObservableIdentifiedFolderContentsElement<Value, Key>(
                        url: FileURL(url),
                        id: nil
                    )
                    
                    var fileConfiguration: _RelativeFileConfiguration<Value> = try parent.fileConfiguration(element)
                    let relativeFilePath: String = try fileConfiguration.consumePath()
                    var fileURL: FileURL {
                        get throws {
                            try FileURL(parent.folder._toURL().appendingPathComponent(relativeFilePath))
                        }
                    }
                    
                    let fileCoordinator = try _FileStorageCoordinators.RegularFile<MutableValueBox<Value>, Value>(
                        fileSystemResource: {
                            try fileURL
                        },
                        configuration: fileConfiguration
                    )
                    
                    #try(.optimistic) {
                        try _withLogicalParent(ofType: AnyObject.self) {
                            fileCoordinator._enclosingInstance = $0
                        }
                    }
                    
                    let item: Value = try fileCoordinator._wrappedValue
                    let key: Key
                    
                    if let id = parent.id {
                        key = id(item)
                    } else if Key.self == URL.self {
                        key = try cast(fileURL._toURL())
                    } else {
                        throw Never.Reason.illegal
                    }
                    
                    parent.storage[key] = fileCoordinator
                    
                    result[key] = item
                } catch {
                    runtimeIssue(error)
                    
                    continue
                }
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
            try parent.cocoaFileManager.createDirectory(at: directory, withIntermediateDirectories: true)

            let difference = Set(newValue.keys).symmetricDifference(Set(oldValue.keys))
            
            var removedKeys = Set<Key>()
            var insertedKeys = Set<Key>()
            
            for key in difference {
                if oldValue[key] == nil {
                    insertedKeys.insert(key)
                } else {
                    removedKeys.insert(key)
                }
            }
            
            var updatedNewValue: WrappedValue = oldValue
            
            for key in removedKeys {
                let fileURL: URL = try parent.storage[key].unwrap().fileSystemResource._toURL()
                
                assert(parent.cocoaFileManager.regularFileExists(at: fileURL))
                
                parent.storage[key]?.discard()
                parent.storage[key] = nil
                
                updatedNewValue[key] = nil
                
                try parent.cocoaFileManager.removeItemIfNecessary(at: fileURL)
            }
            
            for key in insertedKeys {
                let item: Value = newValue[key]!
                let element: _ObservableIdentifiedFolderContentsElement = _ObservableIdentifiedFolderContentsElement(value: .inMemory(item), id: key)
                var fileConfiguration: _RelativeFileConfiguration<Value> = try parent.fileConfiguration(element)
                let relativeFilePath: String = try fileConfiguration.consumePath()
                let fileURL: URL = directory.appendingPathComponent(relativeFilePath)
                
                fileConfiguration.serialization?.initialValue = .available(item)
                                
                let fileCoordinator = try! _FileStorageCoordinators.RegularFile<MutableValueBox<Value>, Value>(
                    fileSystemResource: { FileURL(fileURL) },
                    configuration: fileConfiguration
                )
                
                fileCoordinator.commit()
                
                parent.storage[key] = fileCoordinator
                updatedNewValue[key] = item
            }
            
            let updatedKeys = Set(oldValue.keys).subtracting(removedKeys)
            
            for key in updatedKeys {
                if let updatedElement = newValue[key] {
                    if Value.self is (any Equatable).Type {
                        if AnyEquatable.equate(updatedElement, oldValue[key]) {
                            continue
                        }
                    }
                    
                    parent.storage[key]!.wrappedValue = updatedElement
                    updatedNewValue[key] = updatedElement
                }
            }
        }
    }
    
    public struct _IdentifierIndexingArray<Item, ID: Hashable>: _ObservableIdentifiedFolderContentsUpdating {
        public typealias WrappedValue = IdentifierIndexingArray<Item, ID>
        public typealias FolderContentsType = _ObservableIdentifiedFolderContents<Item, ID, IdentifierIndexingArray<Item, ID>>
        
        public static func initializePlaceholder(
            for parent: _ObservableIdentifiedFolderContents<Item, ID, IdentifierIndexingArray<Item, ID>>
        ) throws -> IdentifierIndexingArray<Item, ID> {
            let id: ((Item) -> ID) = try parent.id.unwrap()
            
            return IdentifierIndexingArray(id: id)
        }
        
        @MainActor
        public static func initialize(
            from directory: URL,
            for parent: FolderContentsType
        ) throws -> WrappedValue {
            let id: ((Item) -> ID) = try parent.id.unwrap()
            var result = WrappedValue(id: id)
            
            try parent.cocoaFileManager.createDirectoryIfNecessary(at: directory, withIntermediateDirectories: true)
            
            let urls: [URL] = try parent.cocoaFileManager.contentsOfDirectory(at: directory)
            
            for url in urls {
                do {
                    guard !parent.cocoaFileManager.isDirectory(at: url) else {
                        continue
                    }
                    
                    if let filename = url._fileNameWithExtension {
                        guard !parent.cocoaFileManager._practicallyIgnoredFilenames.contains(filename) else {
                            continue
                        }
                    }
                    
                    let element = _ObservableIdentifiedFolderContentsElement<Item, ID>(
                        url: FileURL(url),
                        id: nil
                    )
                    
                    var fileConfiguration = try parent.fileConfiguration(element)
                    let relativeFilePath = try fileConfiguration.consumePath()
                    
                    let fileCoordinator = try _FileStorageCoordinators.RegularFile<MutableValueBox<Item>, Item>(
                        fileSystemResource: {
                            try FileURL(parent.folder._toURL().appendingPathComponent(relativeFilePath))
                        },
                        configuration: fileConfiguration
                    )
                    
                    #try(.optimistic) {
                        try _withLogicalParent(ofType: AnyObject.self) {
                            fileCoordinator._enclosingInstance = $0
                        }
                    }
                    
                    let item: Item = try fileCoordinator._wrappedValue
                    let itemID: ID = id(item)
                    
                    parent.storage[itemID] = fileCoordinator
                    
                    result.append(item)
                } catch {
                    runtimeIssue(error)
                }
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
                
                if let coordinator = parent.storage[key] {
                    if coordinator.stateFlags.contains(.didWriteOnce) {
                        assert(parent.cocoaFileManager.regularFileExists(at: fileURL))
                    }
                    
                    coordinator.discard()
                    
                    parent.storage[key] = nil
                }
                
                updatedNewValue[id: key] = nil
                
                try parent.cocoaFileManager.removeItemIfNecessary(at: fileURL)
            }
            
            for key in difference.insertions {
                guard renamedKeys[key] == nil else {
                    fatalError(.unexpected)
                }
                
                let item: Item = newValue[id: key]!
                let element = _ObservableIdentifiedFolderContentsElement(
                    value: newValue[id: key]!,
                    id: key
                )
                
                var fileConfiguration: _RelativeFileConfiguration<Item> = try parent.fileConfiguration(element)
                let relativeFilePath: String = try fileConfiguration.consumePath()
                let fileURL: URL = directory.appendingPathComponent(relativeFilePath)
                
                fileConfiguration.serialization?.initialValue = .available(item)
                
                try parent.cocoaFileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                
                let fileCoordinator = try! _FileStorageCoordinators.RegularFile<MutableValueBox<Item>, Item>(
                    fileSystemResource: { FileURL(fileURL) },
                    configuration: fileConfiguration
                )
                
                fileCoordinator.commit()
                
                parent.storage[key] = fileCoordinator
                updatedNewValue[id: key] = item
            }
            
            let updated = updatedNewValue._unorderedIdentifiers.removing(contentsOf: difference.insertions)
            
            for identifier in updated {
                let updatedElement = newValue[id: identifier]!
                let fileCoordinator = parent.storage[identifier]!
                
                fileCoordinator.wrappedValue = updatedElement
                
                updatedNewValue[id: identifier] = updatedElement
                
                fileCoordinator.commit()
            }
        }
    }
}
