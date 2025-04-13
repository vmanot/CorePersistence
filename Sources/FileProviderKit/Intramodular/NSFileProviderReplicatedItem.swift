//
// Copyright (c) Vatsal Manot
//

import FileProvider
import UniformTypeIdentifiers

public class NSFileProviderReplicatedItem: NSObject, NSFileProviderItem {
    public let itemIdentifier: NSFileProviderItemIdentifier
    public let parentItemIdentifier: NSFileProviderItemIdentifier
    public let filename: String
    public let contentType: UTType
    public let sourceURL: URL?
    public let isRoot: Bool
    public let itemVersion: NSFileProviderItemVersion
    public let children: [NSFileProviderReplicatedItem]?
    
    public init(
        itemIdentifier: NSFileProviderItemIdentifier,
        parentItemIdentifier: NSFileProviderItemIdentifier,
        filename: String,
        contentType: UTType,
        sourceURL: URL? = nil,
        isRoot: Bool = false,
        children: [NSFileProviderReplicatedItem]? = nil,
        itemVersion: NSFileProviderItemVersion?
    ) {
        self.itemIdentifier = itemIdentifier
        self.parentItemIdentifier = parentItemIdentifier
        self.filename = filename
        self.contentType = contentType
        self.sourceURL = sourceURL
        self.isRoot = isRoot
        self.children = children
        self.itemVersion = itemVersion ?? NSFileProviderItemVersion(
            contentVersion: "1".data(using: .utf8)!,
            metadataVersion: "1".data(using: .utf8)!
        )
        
        super.init()
    }
    
    public var capabilities: NSFileProviderItemCapabilities {
        var caps: NSFileProviderItemCapabilities = [.allowsReading, .allowsDeleting]
        
        if contentType == .folder || isRoot {
            caps.insert(.allowsAddingSubItems)
            caps.insert(.allowsContentEnumerating)
        }
        
        if !isRoot {
            caps.insert(.allowsWriting)
            caps.insert(.allowsRenaming)
        }
        
        return caps
    }
    
    public var documentSize: NSNumber? {
        guard let sourceURL = sourceURL else {
            return 0
        }
        
        return (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? NSNumber) ?? 0
    }
    
    public var contentModificationDate: Date? {
        guard let sourceURL = sourceURL else {
            return Date()
        }
        
        return (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.modificationDate] as? Date) ?? Date()
    }
    
    public var isDownloaded: Bool {
        if isRoot {
            return true
        }
        
        return sourceURL != nil
    }
    
    public var isUploaded: Bool {
        return true
    }
    
    public var isMaterialized: Bool {
        if isRoot {
            return true
        }
        
        return isDownloaded
    }
}
