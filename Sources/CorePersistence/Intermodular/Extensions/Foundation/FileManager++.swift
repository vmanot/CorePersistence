//
// Copyright (c) Vatsal Manot
//

#if canImport(Cocoa)
import Cocoa
#endif
import FoundationX
import Swallow
import System

#if canImport(Cocoa)
extension FileManager {
    @discardableResult
    public func acquireSandboxAccess(
        to location: FileLocationResolvable,
        openPanelMessage: String? = nil
    ) throws -> BookmarkedURL {
        let location: BookmarkedURL = try location.resolveFileLocation()
        
        if isReadableAndWritable(at: location.url) {
            return location
        }
        
        if let bookmarkData: Data = location.bookmarkData {
            do {
                var isBookmarkStale = false
                let cachedURL = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isBookmarkStale)
                
                if !isBookmarkStale {
                    if isReadableAndWritable(at: cachedURL) {
                        return location
                    } else {
                        throw SandboxFolderAccessError()
                    }
                } else {
                    throw SandboxFolderAccessError()
                }
            } catch {
                return try acquireSandboxAccess(
                    to: location.discardingBookmarkData(),
                    openPanelMessage: openPanelMessage
                )
            }
        }
        
        #if os(macOS)
        let openPanel = NSOpenPanel()
        #else
        let NSOpenPanel_Type = unsafeBitCast(NSClassFromString("NSOpenPanel"), to: _NSOpenPanelProtocol.Type.self)

        let openPanel = _NSOpenPanel_Type.init()
        #endif
        
        openPanel.directoryURL = location.url
        openPanel.message = openPanelMessage
        openPanel.prompt = "Open"
        
        if #available(macOS 12.0, *) {
            #if os(macOS)
            openPanel.allowedContentTypes = []
            #else
            openPanel.allowedFileTypes = ["none"]
            #endif
        } else {
            openPanel.allowedFileTypes = ["none"]
        }
        
        openPanel.allowsOtherFileTypes = false
        openPanel.canChooseDirectories = true
        
        openPanel.runModal()
        
        if let folderUrl = openPanel.urls.first {
            if try folderUrl.resolveFileURL() != location.resolveFileURL().resolvingSymlinksInPath() {
                #if os(macOS)
                let alert = NSAlert()
                alert.alertStyle = .informational
                #else
                let alert = _NSAlert_Type.init()
                alert.alertStyle = 1
                #endif
                
                alert.messageText = "Can't get access to \(location.url.path) folder"
                alert.informativeText = "Did you choose the right folder?"
                
                alert.addButton(withTitle: "Repeat")
                
                alert.runModal()
                
                return try acquireSandboxAccess(
                    to: location.discardingBookmarkData(), 
                    openPanelMessage: openPanelMessage
                )
            }
            
            if isReadableAndWritable(at: folderUrl) {
                if let bookmarkData = try? folderUrl.bookmarkData() {
                    return BookmarkedURL(url: folderUrl, bookmarkData: bookmarkData)!
                }
            } else {
                throw SandboxFolderAccessError()
            }
        } else {
            throw SandboxFolderAccessError()
        }
        
        return try acquireSandboxAccess(
            to: location.discardingBookmarkData(),
            openPanelMessage: openPanelMessage
        )
    }
}

extension FileManager {
    fileprivate struct SandboxFolderAccessError: Error {
        
    }
}

#endif

// MARK: - Internal

#if targetEnvironment(macCatalyst)

@objc fileprivate protocol _NSAlertProtocol: NSObjectProtocol {
    @objc var alertStyle: UInt { get set }
    @objc var messageText: String { get set }
    @objc var informativeText: String { get set }
    
    @objc func addButton(withTitle: String)
    @objc func runModal()
    
    init()
}

@objc fileprivate protocol _NSOpenPanelProtocol: NSObjectProtocol {
    @objc var directoryURL: URL? { get set }
    @objc var message: String? { get set }
    @objc var prompt: String? { get set }
    @objc var allowedFileTypes: [String]? { get set }
    @objc var allowsOtherFileTypes: Bool { get set }
    @objc var canChooseDirectories: Bool { get set }
    @objc var urls: [URL] { get set }
    
    @objc func runModal()
    
    init()
}

fileprivate let _NSAlert_Type = unsafeBitCast(NSClassFromString("NSAlert"), to: _NSAlertProtocol.Type.self)
fileprivate let _NSOpenPanel_Type = unsafeBitCast(NSClassFromString("NSOpenPanel"), to: _NSOpenPanelProtocol.Type.self)

#endif
