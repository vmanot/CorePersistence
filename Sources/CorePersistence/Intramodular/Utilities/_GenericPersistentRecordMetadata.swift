//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct _GenericPersistentRecordMetadata: Codable, Hashable, Sendable {
    @LossyCoding
    public var timestamps: [TimestampKind: Date] = [:]
    @LossyCoding
    public var isTombstoned: Bool? = false
}

extension _GenericPersistentRecordMetadata {
    public enum TimestampKind: String, Codable, Hashable, Sendable {
        case creation
        case insertion
        case modification
        case access
        case publication
        case deletion
        case archival
    }
}
