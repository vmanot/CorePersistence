//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift
import System
import UniformTypeIdentifiers

public struct FilenameExtension:
    RawRepresentable,
    ExpressibleByStringLiteral,
    Codable,
    Sendable,
    Hashable,
    Comparable,
    CustomStringConvertible
{
    public let rawValue: String
        
    public init(
        _ candidate: String
    ) throws {
        let stripped = candidate.hasPrefix(".") ? String(candidate.dropFirst()) : candidate
        let lower = stripped.lowercased()
        
        guard Self.isValid(lower) else {
            throw ValidationError.invalidExtension(candidate)
        }
        
        self.rawValue = lower
    }
    
    public init?<S: StringProtocol>(
        unchecked candidate: S
    ) {
        self.init(rawValue: String(candidate))
        
        guard Self.isValid(rawValue) else {
            return nil
        }
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }
    
    public init(stringLiteral value: StringLiteralType) {
        guard let ext = FilenameExtension(unchecked: value) else {
            preconditionFailure("Invalid FilenameExtension literal: '\(value)'")
        }
        
        self = ext
    }
    
    public var withoutDot: String {
        rawValue
    }
    
    public var withDot: String    {
        "." + rawValue
    }
    
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public var utType: UTType? {
        UTType(
            filenameExtension: rawValue
        )
    }
    
    public var description: String {
        withoutDot
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    private static let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789+-")
    
    private static func isValid(
        _ candidate: String
    ) -> Bool {
        guard (1...15).contains(candidate.utf8.count) else { return false }
        return candidate.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    public enum ValidationError: Error, CustomStringConvertible {
        case invalidExtension(String)
        public var description: String {
            switch self {
                case .invalidExtension(let ext): return "'\(ext)' is not a valid file extension"
            }
        }
    }
}

extension URL {
    public func appendingPathExtension(_ ext: FilenameExtension) -> URL {
        self.appendingPathExtension(ext.withoutDot)
    }
}
