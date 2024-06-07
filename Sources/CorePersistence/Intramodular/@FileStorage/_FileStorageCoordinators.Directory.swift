//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

extension _FileStorageCoordinators {
    public final class Directory<Item, ID: Hashable, WrappedValue>: _AnyFileStorageCoordinator<_ObservableIdentifiedFolderContents<Item, ID, WrappedValue>, WrappedValue> {
        public typealias Base = _ObservableIdentifiedFolderContents<Item, ID, WrappedValue>
        
        override public var objectWillChange: ObjectWillChangePublisher {
            base.objectWillChange
        }

        override public var objectDidChange: _ObjectDidChangePublisher {
            base.objectDidChange
        }
        
        @MainActor(unsafe)
        @PublishedObject private var base: Base
        
        @MainActor
        public var _hasReadWithLogicalParentAtLeastOnce = false
        
        @MainActor(unsafe)
        public override var wrappedValue: WrappedValue {
            get {
                guard _hasReadWithLogicalParentAtLeastOnce else {
                    guard let _enclosingInstance else {
                        return base.wrappedValue
                    }
                    
                    return try! _withLogicalParent(_enclosingInstance) {
                        base.wrappedValue
                    }
                }
                
                return base.wrappedValue
            } set {
                #try(.optimistic) {
                    try _withLogicalParent(_enclosingInstance) {
                        base.wrappedValue = newValue
                    }
                }
            }
        }
        
        @MainActor(unsafe)
        public init(
            base: Base
        ) throws {
            self.base = base
            
            try super.init(
                fileSystemResource: FileURL(try base.folderURL),
                configuration: .init(
                    path: nil,
                    serialization: .init(
                        contentType: nil,
                        coder: _AnyTopLevelFileDecoderEncoder(
                            .topLevelDataCoder(JSONCoder(), forType: Never.self)
                        ),
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
