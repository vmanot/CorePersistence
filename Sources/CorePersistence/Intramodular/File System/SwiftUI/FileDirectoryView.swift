//
// Copyright (c) Vatsal Manot
//

#if canImport(SwiftUI) && (os(iOS) || targetEnvironment(macCatalyst))

import FoundationX
import Swift
import SwiftUIX
import System

@available(iOS 14.0, *)
public struct FileDirectoryView: FileLocationInitiable, View {
    public let location: BookmarkedURL
    
    public init(_ location: BookmarkedURL) {
        self.location = location
    }
    
    public init(_ location: CanonicalFileDirectory) throws {
        self.location = try BookmarkedURL(url: location.toURL()).unwrap()
    }
    
    @ViewBuilder
    public var body: some View {
        withInlineStateObject(ObservableFileDirectory(url: location.url)) { directory in
            ZStack {
                if let children = directory.children, !children.isEmpty {
                    List {
                        OutlineGroup(
                            children.compactMap(BookmarkedURL.init(url:)),
                            children: \.children,
                            content: FileItemRowView.init
                        )
                    }
                    .listStyle(InsetGroupedListStyle())
                } else {
                    Text("No Files")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .fixedSize()
                        .padding(.bottom)
                }
            }
            .navigationTitle(Text(location.path.lastComponent))
        }
        .id(location)
    }
}

extension BookmarkedURL {
    fileprivate var children: [BookmarkedURL]? {
        let result = try? FileManager.default
            .suburls(at: url)
            .map(BookmarkedURL.init(_unsafe:))
            .filter({ $0.path.exists })
        
        return (result ?? []).isEmpty ? nil : result
    }
}

#endif
