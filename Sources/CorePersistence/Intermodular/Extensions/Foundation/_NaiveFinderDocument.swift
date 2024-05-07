//
// Copyright (c) Vatsal Manot
//

import CoreTransferable
import Foundation
import Swallow

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct _NaiveFinderDocument: Codable, Hashable, Identifiable, Sendable {
    public let url: URL
    
    public var id: URL {
        url
    }
    
    public init(url: URL) {
        self.url = url
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension _NaiveFinderDocument: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .fileURL) { (document: _NaiveFinderDocument) in
            SentTransferredFile(document.url)
        } importing: { received in
            let url = received.file
            
            return Self(url: url)
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension _NaiveFinderDocument {
    public var name: String {
        url._fileNameWithExtension ?? "Untitled"
    }
}
