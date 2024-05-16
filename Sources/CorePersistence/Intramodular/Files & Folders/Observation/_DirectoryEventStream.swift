//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import CoreServices
import FoundationX
@_spi(Internal) import Swallow

public class DirectoryEventStream {
    public typealias EventCallback = ([Event]) -> Void
    
    private var streamRef: FSEventStreamRef?
    private let callback: EventCallback
    private let debounceDuration: TimeInterval
    
    public struct Event {
        public let filePath: String
        public let eventType: FSEvent
        
        public var url: URL {
            URL(fileURLWithPath: filePath)
        }
    }
    
    public init(
        directory: String,
        debounceDuration: TimeInterval = 0.1,
        callback: @escaping EventCallback
    ) {
        self.debounceDuration = debounceDuration
        self.callback = callback
        startEventStream(directory: directory)
    }
    
    deinit {
        stopEventStream()
    }
    
    public func cancel() {
        stopEventStream()
    }
    
    private func startEventStream(directory: String) {
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        var context = FSEventStreamContext(version: 0, info: selfPtr, retain: nil, release: nil, copyDescription: nil)
        let contextPtr = withUnsafeMutablePointer(to: &context) { UnsafeMutablePointer($0) }
        
        let cfDirectory = directory as CFString
        let pathsToWatch = [cfDirectory] as CFArray
        
        let flags: FSEventStream.CreateFlags = [
            .useCFTypes,
            .fileEvents,
            .useExtendedData
        ]
        
        if let ref = FSEventStreamCreate(
            kCFAllocatorDefault,
            eventStreamCallback,
            contextPtr,
            pathsToWatch,
            UInt64(kFSEventStreamEventIdSinceNow),
            debounceDuration,
            FSEventStreamCreateFlags(flags.rawValue)
        ) {
            streamRef = ref
            FSEventStreamSetDispatchQueue(ref, DispatchQueue.global(qos: .default))
            FSEventStreamStart(ref)
        }
    }
    
    private func stopEventStream() {
        if let streamRef {
            FSEventStreamStop(streamRef)
            FSEventStreamInvalidate(streamRef)
            FSEventStreamRelease(streamRef)
        }
        streamRef = nil
    }
    
    private let eventStreamCallback: FSEventStreamCallback = { streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds in
        guard let clientCallBackInfo else {
            return
        }
        
        let eventStream = Unmanaged<DirectoryEventStream>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
       
        eventStream.handleEvents(
            numEvents: numEvents,
            eventPaths: eventPaths,
            eventFlags: eventFlags
        )
    }
    
    private func handleEvents(numEvents: Int, eventPaths: UnsafeMutableRawPointer, eventFlags: UnsafePointer<FSEventStreamEventFlags>) {
        guard let eventDictionaries = unsafeBitCast(eventPaths, to: NSArray.self) as? [NSDictionary] else {
            return
        }
        
        var events: [Event] = []
        
        for (index, dictionary) in eventDictionaries.enumerated() {
            guard let path = dictionary[kFSEventStreamEventExtendedDataPathKey] as? String,
                  let event = FSEvent(rawValue: eventFlags[index])
            else {
                continue
            }
            
            events.append(DirectoryEventStream.Event(filePath: path, eventType: event))
        }
        
        callback(events)
    }
}

extension DirectoryEventStream {
    public enum FSEvent {
        case changeInDirectory
        case rootChanged
        case itemChangedOwner
        case itemCreated
        case itemCloned
        case itemModified
        case itemRemoved
        case itemRenamed
        
        init?(rawValue: FSEventStreamEventFlags) {
            if rawValue == 0 {
                self = .changeInDirectory
            } else if rawValue & UInt32(kFSEventStreamEventFlagRootChanged) > 0 {
                self = .rootChanged
            } else if rawValue & UInt32(kFSEventStreamEventFlagItemChangeOwner) > 0 {
                self = .itemChangedOwner
            } else if rawValue & UInt32(kFSEventStreamEventFlagItemCreated) > 0 {
                self = .itemCreated
            } else if rawValue & UInt32(kFSEventStreamEventFlagItemCloned) > 0 {
                self = .itemCloned
            } else if rawValue & UInt32(kFSEventStreamEventFlagItemModified) > 0 {
                self = .itemModified
            } else if rawValue & UInt32(kFSEventStreamEventFlagItemRemoved) > 0 {
                self = .itemRemoved
            } else if rawValue & UInt32(kFSEventStreamEventFlagItemRenamed) > 0 {
                self = .itemRenamed
            } else {
                return nil
            }
        }
    }
}

#endif
