//
// Copyright (c) Vatsal Manot
//

import _ModularDecodingEncoding
import Foundation
import Swallow
import UniformTypeIdentifiers

public struct _FileOrFolderSerializationConfiguration<Value> {
    public let contentType: UTType?
    public let coder: any _TopLevelFileDecoderEncoder
    @ReferenceBox
    package var initialValue: _ThrowingMaybeLazy<Value?>
    
    public init(
        contentType: UTType?,
        coder: any _TopLevelFileDecoderEncoder,
        initialValue: @escaping () throws -> Value
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
    
    public init(
        contentType: UTType?,
        coder: any _TopLevelFileDecoderEncoder,
        initialValue: @escaping () throws -> Value?
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
    
    public init(
        contentType: UTType?,
        coder: any _TopLevelFileDecoderEncoder,
        initialValue: Value?
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
}
