//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

extension _FileStorageCoordinators {
    @MainActor
    public final class Directory<Item, ID: Hashable>: _AnyFileStorageCoordinator<_ObservableIdentifiedFolderContents<Item, ID>, _ObservableIdentifiedFolderContents<Item, ID>.WrappedValue> {
        public typealias Base = _ObservableIdentifiedFolderContents<Item, ID>
        
        @PublishedObject var base: Base
        
        @MainActor(unsafe)
        public override var wrappedValue: _ObservableIdentifiedFolderContents<Item, ID>.WrappedValue {
            get {
                base.wrappedValue
            } set {
                base.wrappedValue = newValue
            }
        }
        
        public init(
            base: Base
        ) throws {
            self.base = base
            
            try super.init(
                fileSystemResource: try base.folderURL.toFileURL(),
                configuration: .init(
                    path: nil,
                    serialization: .init(
                        contentType: nil,
                        coder: _AnyConfiguredFileCoder(rawValue: .topLevelData(.topLevelDataCoder(JSONCoder(), forType: Never.self))),
                        initialValue: nil
                    ),
                    readWriteOptions: .init(
                        readErrorRecoveryStrategy: .discardAndReset
                    )
                )
            )
        }
        
        override public func commit() {
            // do nothing
        }
    }
}
