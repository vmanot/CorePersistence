//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public enum FileAccessMode: Hashable {
    case read
    case write
    case update
}

public protocol FileAccessModeType: _StaticValue {
    static var value: FileAccessMode { get }
}

public protocol FileAccessModeTypeForWriting: FileAccessModeType {
    static var value: FileAccessMode { get }
}

public protocol FileAccessModeTypeForReading: FileAccessModeType {
    static var value: FileAccessMode { get }
}

// MARK: - Conformances

public struct ReadAccess: FileAccessModeTypeForReading {
    public static let value: FileAccessMode = .read
}

public struct WriteAccess: FileAccessModeTypeForWriting {
    public static let value: FileAccessMode = .write
}

public struct UpdateAccess: FileAccessModeTypeForUpdating {
    public static let value: FileAccessMode = .update
}

// MARK: - Auxiliary

extension FileHandle {
    public convenience init(forURL url: URL, accessMode mode: FileAccessMode) throws {
        switch mode {
            case .read:
                try self.init(forReadingFrom: url)
            case .write:
                try self.init(forWritingTo: url)
            case .update:
                try self.init(forUpdating: url)
        }
    }
}

// MARK: - Helpers

public typealias FileAccessModeTypeForUpdating = FileAccessModeTypeForReading & FileAccessModeTypeForWriting
