//
// Copyright (c) Vatsal Manot
//

import _SwiftFileSystem
import Swallow
import SwiftUI
import UniformTypeIdentifiers

@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct TextFileDocument: Codable, PersistentFileDocument, Hashable, Initiable {
    public static var readableContentTypes = [UTType.plainText]
    
    public var text: String
    
    public init(text: String) {
        self.text = text
    }
    
    public init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    public init() {
        self.init(text: String())
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try text.data(using: .utf8).unwrap())
    }
}
