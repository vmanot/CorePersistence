//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

protocol _FileBundleContainerElement: _FileBundleElement, ObservableObject {
    func childDidUpdate(_ node: any _FileBundleChild)
}
