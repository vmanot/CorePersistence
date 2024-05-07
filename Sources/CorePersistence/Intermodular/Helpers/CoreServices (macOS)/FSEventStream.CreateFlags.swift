//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import CoreServices
#else
import MobileCoreServices
#endif

import Foundation
import Swallow

extension FSEventStream {
    public struct CreateFlags: RawRepresentable {
        public typealias RawValue = Int
        
        public let rawValue: RawValue
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Conformances

extension FSEventStream.CreateFlags: CustomStringConvertibleOptionSet {
    #if os(macOS)
    public static let none = Self(rawValue: kFSEventStreamCreateFlagNone)
    public static let useCFTypes = Self(rawValue: kFSEventStreamCreateFlagUseCFTypes)
    public static let flagNoDefer = Self(rawValue: kFSEventStreamCreateFlagNoDefer)
    public static let watchRoot = Self(rawValue: kFSEventStreamCreateFlagWatchRoot)
    public static let ignoreSelf = Self(rawValue: kFSEventStreamCreateFlagIgnoreSelf)
    public static let fileEvents = Self(rawValue: kFSEventStreamCreateFlagFileEvents)
    public static let markSelf = Self(rawValue: kFSEventStreamCreateFlagMarkSelf)
    public static let useExtendedData = Self(rawValue: kFSEventStreamCreateFlagUseExtendedData)
    
    public static let descriptions: [Self: String] =
    [
        .none: "none",
        .useCFTypes: "useCFTypes",
        .flagNoDefer: "flagNoDefer",
        .watchRoot: "watchRoot",
        .ignoreSelf: "ignoreSelf",
        .fileEvents: "fileEvents",
        .markSelf: "markSelf",
        .useExtendedData: "useExtendedData"
    ]
    #else
    public static let descriptions: [Self: String] = [:]
    #endif
}

extension FSEventStream.CreateFlags: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
