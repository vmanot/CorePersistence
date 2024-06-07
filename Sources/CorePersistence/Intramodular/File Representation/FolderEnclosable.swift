//
// Copyright (c) Vatsal Manot
//

import FoundationX

/// A resource that can be completely enclosed within a folder.
public protocol FolderEnclosable {
    var topLevelFileContents: [URL.PathComponent] { get throws }
}
