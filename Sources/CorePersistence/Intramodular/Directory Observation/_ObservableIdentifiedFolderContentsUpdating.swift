//
// Copyright (c) Vatsal Manot
//

import Foundation
import SwiftDI

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
                
                #try(.optimistic) {
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
