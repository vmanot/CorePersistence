//
// Copyright (c) Vatsal Manot
//

#if canImport(SwiftUI) && (os(iOS) || targetEnvironment(macCatalyst))

import Foundation
import Swallow
import SwiftUIX
import System

public struct FileItemRowView: View {
    @Environment(\.fileManager) var fileManager
    
    public let location: BookmarkedURL
    
    public init(location: BookmarkedURL) {
        self.location = location
    }
    
    public var body: some View {
        PassthroughView {
            if try! FilePath(fileURL: location.url).resolveFileType() == .directory {
                DirectoryView(location: location)
            } else {
                RegularFileView(location: location)
            }
        }
        .contextMenu {
            ContextMenu(location: location)
        }
        .disabled(!location.isReachable)
    }
    
    struct ContextMenu: View {
        @Environment(\.fileManager) var fileManager
        
        let location: BookmarkedURL
        
        var body: some View {
            Section {
                Button("Delete", systemImage: .trash) {
                    try! fileManager.removeItem(at: location.url)
                }
                .foregroundColor(.red)
                .disabled(!fileManager.isWritableFile(atPath: location.path.stringValue))
            }
            
            PresentationLink(destination: AppActivityView(activityItems: [location.url])) {
                Label("Share", systemImage: .squareAndArrowUp)
            }
        }
    }
    
    struct RegularFileView: View {
        @Environment(\.presenter) var presenter
        @Environment(\.fileManager) var fileManager
        
        let location: BookmarkedURL
        
        var body: some View {
            Label(
                location.url.lastPathComponent,
                systemImage: .docFill
            )
        }
    }
    
    struct DirectoryView: View {
        @Environment(\.fileManager) var fileManager
        
        let location: BookmarkedURL
        
        var body: some View {
            HStack {
                Label(
                    location.url.lastPathComponent,
                    systemImage: location.hasChildren ? .folderFill : .folder
                )
                
                Spacer()
            }
            .onPress(navigateTo: FileDirectoryView(location))
            .disabled(!location.hasChildren || !location.isReachable)
        }
    }
}

#endif