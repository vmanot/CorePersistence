//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct FileSystemIdentifier: Codable, Hashable, Sendable, URLInitiable {
    private let inodeNumber: UInt64
    public let deviceID: UInt64
    
    // Initializer that takes a file path and retrieves the inode and device IDs
    public init(
        path: String
    ) throws {
        let fileURL = URL(fileURLWithPath: path)
        
        var inodeNumber: UInt64? = nil
        
        // Attempt to retrieve the identifier using URLResourceValues
        if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileResourceIdentifierKey]),
           let fileIdentifier = resourceValues.fileResourceIdentifier as? NSData {
            inodeNumber = fileIdentifier.withUnsafeBytes { $0.load(as: UInt64.self) }
        }
        
        // Fallback to the lower-level POSIX method
        var statInfo = stat()
        if stat(path, &statInfo) == 0 {
            self.inodeNumber = inodeNumber ?? UInt64(statInfo.st_ino)
            self.deviceID = UInt64(statInfo.st_dev)
        } else {
            throw FileSystemIdentifierError.posixStatFailed(errno: errno)
        }
    }
    
    public init(url: URL) throws {
        try self.init(path: url._filePath)
    }
    
    public init(bookmark: URL.Bookmark) throws {
        try self.init(url: try bookmark.toURL())
    }
}

// MARK: - Conformances

extension FileSystemIdentifier: CustomStringConvertible {
    public var description: String {
        return "Inode Number: \(inodeNumber), Device ID: \(deviceID)"
    }
}

// MARK: - Error Handling

extension FileSystemIdentifier {
    // Custom error type for FileSystemIdentifier initialization
    enum FileSystemIdentifierError: Error, CustomStringConvertible {
        case urlResourceValuesFailed
        case posixStatFailed(errno: Int32)
        
        var description: String {
            switch self {
                case .urlResourceValuesFailed:
                    return "Failed to retrieve file identifier using URL resource values."
                case .posixStatFailed(let errno):
                    return "Failed to retrieve file identifier using POSIX stat with error code: \(errno)."
            }
        }
    }
}
