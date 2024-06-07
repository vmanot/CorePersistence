//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import UniformTypeIdentifiers

public struct _FileOrFolderSerializationConfiguration<Value> {
    let contentType: UTType?
    let coder: any _TopLevelFileDecoderEncoder
    @ReferenceBox
    var initialValue: _ThrowingMaybeLazy<Value?>
    
    init(
        contentType: UTType?,
        coder: any _TopLevelFileDecoderEncoder,
        initialValue: @escaping () throws -> Value
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
    
    init(
        contentType: UTType?,
        coder: any _TopLevelFileDecoderEncoder,
        initialValue: @escaping () throws -> Value?
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
    
    init(
        contentType: UTType?,
        coder: any _TopLevelFileDecoderEncoder,
        initialValue: Value?
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
}
