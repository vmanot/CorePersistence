//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import UniformTypeIdentifiers

public struct _FileOrFolderSerializationConfiguration<Value> {
    let contentType: UTType?
    let coder: _AnyConfiguredFileCoder
    @ReferenceBox
    var initialValue: _ThrowingMaybeLazy<Value?>
    
    init(
        contentType: UTType?,
        coder: _AnyConfiguredFileCoder,
        initialValue: @escaping () throws -> Value
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
    
    init(
        contentType: UTType?,
        coder: _AnyConfiguredFileCoder,
        initialValue: @escaping () throws -> Value?
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
    
    init(
        contentType: UTType?,
        coder: _AnyConfiguredFileCoder,
        initialValue: Value?
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
}

public struct _RelativeFileConfiguration<Value>: _PartiallyEquatable {
    public var path: String?
    public let serialization: _FileOrFolderSerializationConfiguration<Value>
    public var readWriteOptions: FileStorage<Value>.Options
    
    public init(
        path: String? = nil,
        serialization: _FileOrFolderSerializationConfiguration<Value>,
        readWriteOptions: FileStorage<Value>.Options
    ) {
        self.path = path
        self.serialization = serialization
        self.readWriteOptions = readWriteOptions
    }
    
    public init(
        path: String? = nil,
        contentType: UTType? = nil,
        coder: _AnyConfiguredFileCoder,
        readWriteOptions: FileStorage<Value>.Options,
        initialValue: Value?
    ) {
        self.path = path
        self.serialization = .init(
            contentType: contentType,
            coder: coder,
            initialValue: initialValue
        )
        self.readWriteOptions = readWriteOptions
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public init(
        path: String? = nil,
        contentType: UTType? = nil,
        readWriteOptions: FileStorage<Value>.Options,
        initialValue: Value? = nil
    ) where Value: Codable {
        let coder = path.flatMap {
            URL(filePath: $0, relativeTo: nil)._suggestedTopLevelDataCoder(contentType: contentType)
        } ?? JSONCoder()
        
        self.init(
            path: path,
            serialization: .init(
                contentType: contentType,
                coder: _AnyConfiguredFileCoder(.topLevelDataCoder(coder, forType: Value.self)),
                initialValue: initialValue
            ),
            readWriteOptions: readWriteOptions
        )
    }
    
    public func isNotEqual(
        to other: Self
    ) -> Bool? {
        if (path != other.path) || (readWriteOptions != other.readWriteOptions) {
            return true
        } else {
            return nil
        }
    }
}
