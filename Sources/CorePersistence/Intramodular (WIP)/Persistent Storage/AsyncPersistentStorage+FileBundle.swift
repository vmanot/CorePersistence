//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension AsyncPersistentStorage {
    public convenience init<Bundle: FileBundle & Initiable>(
        directory: URL
    ) where WrappedValue == [Bundle], ProjectedValue == [Bundle] {
        self.init(
            base: try! _ConcreteFolderAsyncPersistentStorageBase(
                directory: directory,
                resource: { file -> _AnyAsyncPersistentResourceCoordinator? in
                    guard let bundle = try Bundle(directory: file._toURL()) else {
                        return nil
                    }
                    
                    return _AnyAsyncPersistentResourceCoordinator(
                        id: file.id.erasedAsAnyHashable,
                        get: {
                            bundle
                        }
                    )
                }
            )
        )
    }
    
    public convenience init<Bundle: FileBundle & Initiable>(
        directory: CanonicalFileDirectory,
        _ path: String
    ) where WrappedValue == [Bundle], ProjectedValue == [Bundle] {
        try! self.init(directory: directory + path)
    }
}
