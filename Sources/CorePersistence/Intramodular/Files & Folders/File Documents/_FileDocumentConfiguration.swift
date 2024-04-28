//
// Copyright (c) Vatsal Manot
//

import Foundation
import SwiftUI

public struct _FileDocumentConfiguration<Document>: DynamicProperty {
    @Binding public var document: Document
    
    public var fileURL: URL?
    public var isEditable: Bool
    
    public init(
        document: Binding<Document>,
        fileURL: URL? = nil,
        isEditable: Bool
    ) {
        self._document = document
        self.fileURL = fileURL
        self.isEditable = isEditable
    }
}

public struct _ReferenceFileDocumentConfiguration<Document: ObservableObject>: DynamicProperty {
    @ObservedObject public var document: Document
    
    public var fileURL: URL?
    public var isEditable: Bool
    
    public init(
        document: ObservedObject<Document>,
        fileURL: URL? = nil,
        isEditable: Bool
    ) {
        self._document = document
        self.fileURL = fileURL
        self.isEditable = isEditable
    }
}
