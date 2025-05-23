//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

extension _FileStorageCoordinators {
    public final class Directory<Item, ID: Hashable, WrappedValue>: _AnyFileStorageCoordinator<_ObservableIdentifiedFolderContents<Item, ID, WrappedValue>, WrappedValue>, @unchecked Sendable {
        public typealias Base = _ObservableIdentifiedFolderContents<Item, ID, WrappedValue>
        
        override public var objectWillChange: AnyObjectWillChangePublisher {
            AnyObjectWillChangePublisher(from: base)
        }

        override public var objectDidChange: _ObjectDidChangePublisher {
            base.objectDidChange
        }
        
        @PublishedObject private var base: Base
        
        public var _hasReadWithLogicalParentAtLeastOnce = false
        
        public override var wrappedValue: WrappedValue {
            get {
                guard _hasReadWithLogicalParentAtLeastOnce else {
                    guard let _enclosingInstance else {
                        return base.wrappedValue
                    }
                    
                    return _withLogicalParent(_enclosingInstance) {
                        base.wrappedValue
                    }
                }
                
                return base.wrappedValue
            } set {
                _withLogicalParent(_enclosingInstance) {
                    base.wrappedValue = newValue
                }
            }
        }
        
        public init(
            base: Base
        ) throws {
            self.base = base
            
            let url = try FileManager.default.requestingUserGrantedAccessIfPossible(for: base.directoryURL) { url in
                AnyFileURL(url)
            }
            
            try super.init(
                fileSystemResource: url,
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
        
        override public var wantsCommit: Bool {
            self.base.directoryChildrenFileCoordinators.contains(where: { $0.wantsCommit })
        }

        override public func commitUnconditionally() {
            self.base.directoryChildrenFileCoordinators.forEach({ $0.commitUnconditionally() })
        }
    }
}
