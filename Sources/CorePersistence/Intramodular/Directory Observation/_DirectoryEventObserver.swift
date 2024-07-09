//
// Copyright (c) Vatsal Manot
//

import Foundation
@_spi(Internal) import Swallow

public final class _DirectoryEventObserver {
    public typealias Observation = _DirectoryEventObservation
    
    public static let shared = _DirectoryEventObserver()
    
    private let lock = OSUnfairLock()
    private var eventStreams: [URL: DirectoryEventStream] = [:]
    private var observations: [Weak<_DirectoryEventObservation>] = []
    
    private init() {
        
    }
    
    public func observe(
        directories: some Sequence<URL>,
        eventHandler: @escaping ([DirectoryEventStream.Event]) async throws -> Void
    ) -> _DirectoryEventObservation {
        let directories: Set<URL> = Set(directories)
        
        lock.acquireOrBlock()
        
        defer {
            lock.relinquish()
        }
        
        let observation = _DirectoryEventObservation(
            owner: self,
            directories: directories,
            eventHandler: eventHandler
        )
        
        for directory in directories {
            guard eventStreams[directory] == nil else {
                continue
            }

            eventStreams[directory] = DirectoryEventStream(
                directory: directory.path,
                callback: { [weak self] events in
                    guard let `self` = self else {
                        return
                    }
                    
                    Task {
                        try await self.handleEvents(events)
                    }
                }
            )
        }
        
        observations.append(Weak(observation))
        
        return observation
    }
    
    public func observe(
        directory: URL,
        eventHandler: @escaping ([DirectoryEventStream.Event]) async throws -> Void
    ) -> _DirectoryEventObservation {
        observe(directories: [directory], eventHandler: eventHandler)
    }
    
    private func handleEvents(
        _ events: [DirectoryEventStream.Event]
    ) async throws {
        lock.acquireOrBlock()
        let observations = self.observations.filter({ $0.wrappedValue != nil })
        self.observations = observations
        lock.relinquish()
        
        for observation in observations.compactMap({ $0.wrappedValue }) {
            try await observation.handleEvents(events)
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
    private enum StateFlag {
        case ignoreEvents
    }
    
    public enum Option {
        case ignoreHiddenFiles
    }
    
    private weak var owner: _DirectoryEventObserver?
    
    public let directories: Set<URL>
    
    private let eventHandler: ([DirectoryEventStream.Event]) async throws -> Void
    private let options: Set<Option>
    
    private var stateFlags: Set<StateFlag> = []
    
    fileprivate init(
        owner: _DirectoryEventObserver,
        directories: Set<URL>,
        options: Set<Option> = [.ignoreHiddenFiles],
        eventHandler: @escaping ([DirectoryEventStream.Event]) async throws -> Void
    ) {
        self.owner = owner
        self.directories = directories
        self.options = options
        self.eventHandler = eventHandler
    }
    
    public func handleEvents(
        _ events: [DirectoryEventStream.Event]
    ) async throws {
        guard !stateFlags.contains(.ignoreEvents) else {
            return
        }
        
        let filteredEvents: [DirectoryEventStream.Event] = events.filter { (event: DirectoryEventStream.Event) in
            if options.contains(.ignoreHiddenFiles) {
                if event.url._isCanonicallyHiddenFile {
                    return false
                }
            }
            
            return directories.contains(where: { (directory: URL) in
                directory.isAncestor(of: event.url)
            })
        }
        
        guard !filteredEvents.isEmpty else {
            return
        }
        
        try await eventHandler(filteredEvents)
    }
    
    public func cancel() {
        owner?.removeObservation(self)
    }
    
    deinit {
        owner?.removeObservation(self)
    }
    
    public func disableAndPerform<T>(
        _ block: () throws -> T
    ) rethrows -> T {
        do {
            stateFlags.insert(.ignoreEvents)
            
            let result = try block()
            
            stateFlags.remove(.ignoreEvents)
            
            return result
        } catch {
            stateFlags.remove(.ignoreEvents)
            
            throw error
        }
    }
    
    public func disableAndPerform<T>(
        _ block: () async throws -> T
    ) async rethrows -> T {
        do {
            stateFlags.insert(.ignoreEvents)
            
            let result = try await block()
            
            stateFlags.remove(.ignoreEvents)
            
            return result
        } catch {
            stateFlags.remove(.ignoreEvents)
            
            throw error
        }
    }
}
