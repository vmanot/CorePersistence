//
// Copyright (c) Vatsal Manot
//

import Swallow
import SwiftUI
import UniformTypeIdentifiers

public struct WebLocationDocument: Hashable {
    public var url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public init(url: String) throws {
        try self.init(url: URL(string: url).unwrap())
    }
}

// MARK: - Conformances

extension WebLocationDocument: Codable {
    public enum CodingKeys: String, CodingKey {
        case url = "URL"
    }
}

extension WebLocationDocument: FileDocumentX {
    public static var readableContentTypes = [UTType.internetLocation]
    
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        do {
            self = try PropertyListDecoder().decode(Self.self, from: data)
        } catch {
            let payload = try PropertyListDecoder().decode(_WebLocationFilePayload.self, from: data)
            
            self.init(url: try URL(string: payload.url).unwrap())
        }
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try PropertyListEncoder().encode(_WebLocationFilePayload(url: url.absoluteString))
        
        return .init(regularFileWithContents: data)
    }
}

// MARK: - Auxiliary

extension WebLocationDocument {
    struct _WebLocationFilePayload: Codable, Hashable, Sendable {
        enum CodingKeys: String, CodingKey {
            case url = "URL"
        }
        
        let url: String
    }
}
