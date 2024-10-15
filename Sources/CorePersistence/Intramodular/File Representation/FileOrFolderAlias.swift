//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct FileOrFolderAlias: Codable, CustomStringConvertible, Hashable, Sendable {
    public let sourceURL: BookmarkedURL
    
    private let aliasURL: URL
    
    public var url: URL {
        aliasURL
    }
    
    public func resolveSourceURL() throws -> URL {
        sourceURL.url
    }
    
    public var description: String {
        "\(aliasURL.path) (alias)"
    }
}

#if os(macOS)
extension FileOrFolderAlias: URLInitiable {
    public init?(
        url: URL
    ) throws {
        guard url.isFileURL else {
            return nil
        }
        
        let resourceValues = try? url.resourceValues(forKeys: [.isAliasFileKey])
        
        guard let isAlias = resourceValues?.isAliasFile, isAlias else {
            return nil
        }
        
        self.sourceURL = try BookmarkedURL(url: URL(resolvingAliasFileAt: url, options: .withSecurityScope)).unwrap()
        self.aliasURL = url
    }
}
#else
extension FileOrFolderAlias: URLInitiable {
    public init?(
        url: URL
    ) throws {
        guard url.isFileURL else {
            return nil
        }
        
        let resourceValues = try? url.resourceValues(forKeys: [.isAliasFileKey])
        
        guard let isAlias = resourceValues?.isAliasFile, isAlias else {
            return nil
        }
        
        self.sourceURL = try BookmarkedURL(url: URL(resolvingAliasFileAt: url)).unwrap()
        self.aliasURL = url
    }
}
#endif
