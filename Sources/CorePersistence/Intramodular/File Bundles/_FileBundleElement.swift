//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Foundation
import Merge
import Runtime
import Swallow

protocol _FileBundleElement: AnyObject {
    var fileWrapper: _AsyncFileWrapper? { get }
    var knownFileURL: URL? { get throws }
}
