//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
@_spi(Internal) import Swallow

public final class _DirectoryEventObserver {
    public static let shared = _DirectoryEventObserver()
    
    private let lock = OSUnfairLock()
    private var eventStreams: [URL: DirectoryEventStream] = [:]
    private var observations: [Weak<_DirectoryEventObservation>] = []
    
    private init() {}
    
    public func observe(
        directories: some Sequence<URL>,
        eventHandler: @escaping ([DirectoryEventStream.Event]) -> Void
    ) -> _DirectoryEventObservation {
        let directories = Set(directories)
        
        lock.acquireOrBlock()
        defer { lock.relinquish() }
        
        let observation = _DirectoryEventObservation(
            owner: self,
            directories: directories,
            eventHandler: eventHandler
        )
        
        for directory in directories {
            if eventStreams[directory] == nil {
                eventStreams[directory] = DirectoryEventStream(
                    directory: directory.path,
                    callback: { [weak self] events in
                        self?.handleEvents(events)
                    }
                )
            }
        }
        
        observations.append(Weak(observation))
        
        return observation
    }
    
    public func observe(
        directory: URL,
        eventHandler: @escaping ([DirectoryEventStream.Event]) -> Void
    ) -> _DirectoryEventObservation {
        observe(directories: [directory], eventHandler: eventHandler)
    }
    
    private func handleEvents(
        _ events: [DirectoryEventStream.Event]
    ) {
        lock.acquireOrBlock()
        let observations = self.observations.filter({ $0.wrappedValue != nil })
        self.observations = observations
        lock.relinquish()
        
        for observation in observations.compactMap({ $0.wrappedValue }) {
            let filteredEvents: [DirectoryEventStream.Event] = events.filter { (event: DirectoryEventStream.Event) in
                if observation.options.contains(.ignoreHiddenFiles) {
                    if event.url._isCanonicallyHiddenFile {
                        return false
                    }
                }
                
                return observation.directories.contains(where: { (directory: URL) in
                    directory.isAncestor(of: event.url)
                })
            }
            
            guard !filteredEvents.isEmpty else {
                continue
            }
            
            observation.eventHandler(filteredEvents)
        }
    }
    
    fileprivate func removeObservation(
        _ observation: _DirectoryEventObservation
    ) {
        observations.removeAll {
            $0 === observation
        }
        
        for directory in observation.directories {
            if !observations.contains(where: { $0.wrappedValue?.directories.contains(directory) ?? false }) {
                eventStreams[directory]?.cancel()
                eventStreams[directory] = nil
            }
        }
    }
}

public final class _DirectoryEventObservation {
    public enum Option {
        case ignoreHiddenFiles
    }
    
    private weak var owner: _DirectoryEventObserver?
    
    fileprivate let eventHandler: ([DirectoryEventStream.Event]) -> Void
    fileprivate let directories: Set<URL>
    fileprivate let options: Set<Option>
    
    fileprivate init(
        owner: _DirectoryEventObserver,
        directories: Set<URL>,
        options: Set<Option> = [.ignoreHiddenFiles],
        eventHandler: @escaping ([DirectoryEventStream.Event]) -> Void
    ) {
        self.owner = owner
        self.directories = directories
        self.options = options
        self.eventHandler = eventHandler
    }
    
    public func cancel() {
        owner?.removeObservation(self)
    }
    
    deinit {
        owner?.removeObservation(self)
    }
}

#endif
