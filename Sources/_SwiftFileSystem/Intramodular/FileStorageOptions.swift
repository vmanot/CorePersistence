//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// The strategy used to recover from a read error.
public enum _FileStorageReadErrorRecoveryStrategy: String, Codable, Hashable, Sendable {
    /// Halt the execution of the app.
    case fatalError
    /// Discard existing data (if any) and reset with the initial value.
    case discardAndReset
}

public struct FileStorageOptions: Codable, ExpressibleByNilLiteral, Hashable {
    public typealias ReadErrorRecoveryStrategy = _FileStorageReadErrorRecoveryStrategy
    
    public var readErrorRecoveryStrategy: ReadErrorRecoveryStrategy?
    
    public init(
        readErrorRecoveryStrategy: ReadErrorRecoveryStrategy?
    ) {
        self.readErrorRecoveryStrategy = readErrorRecoveryStrategy
    }
    
    public init(nilLiteral: ()) {
        self.readErrorRecoveryStrategy = nil
    }
}
