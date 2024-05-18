//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Foundation

extension DispatchSourceFileSystemObject {
    public typealias Observation = DispatchSourceFileSystemObjectObservation
}

public final class DispatchSourceFileSystemObjectObservation {
    private var source: DispatchSourceFileSystemObject?
    
    public let filePath: String
    public private(set) var fileDescriptor: Int32?
    
    private var subject = PassthroughSubject<DispatchSource.FileSystemEvent, Never>()
    private var onEvent: ((DispatchSource.FileSystemEvent) -> Void)?
    private var continuations: [UUID: AsyncStream<DispatchSource.FileSystemEvent>.Continuation] = [:]
    
    public init(
        filePath: String,
        onEvent: ((DispatchSource.FileSystemEvent) -> Void)? = nil
    ) throws {
        self.filePath = filePath
        self.onEvent = onEvent
        
        try _start()
    }
    
    private func _start() throws {
        let fileDescriptor = try _openFileDescriptor()
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .extend, .attrib],
            queue: DispatchQueue.global()
        )
        
        source.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }
            
            let event = source.data
            
            self.onEvent?(event)
            
            self.subject.send(event)
            
            for continuation in self.continuations.values {
                continuation.yield(event)
            }
        }
        
        source.setCancelHandler { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self._closeFileDescriptor()
            self.source = nil
            
            for continuation in self.continuations.values {
                continuation.finish()
            }
            
            self.continuations.removeAll()
        }
        
        source.resume()
        
        self.source = source
    }
    
    private func _openFileDescriptor() throws -> Int32 {
        guard let path = filePath.cString(using: .utf8) else {
            throw NSError(domain: "Invalid file path", code: 1, userInfo: nil)
        }
        
        let fileDescriptor = open(path, O_EVTONLY)
        
        guard fileDescriptor != -1 else {
            throw NSError(domain: "Failed to open file descriptor", code: 2, userInfo: nil)
        }
        
        self.fileDescriptor = fileDescriptor
        
        return fileDescriptor
    }
    
    private func _closeFileDescriptor() {
        if let fileDescriptor = self.fileDescriptor {
            close(fileDescriptor)
        }
        
        self.fileDescriptor = nil
    }
    
    deinit {
        source?.cancel()
    }
}

extension DispatchSourceFileSystemObjectObservation: AsyncSequence {
    public typealias Element = DispatchSource.FileSystemEvent
    public typealias AsyncIterator = AsyncStream<DispatchSource.FileSystemEvent>.Iterator
    
    public func makeAsyncIterator() -> AsyncIterator {
        let stream = AsyncStream<DispatchSource.FileSystemEvent> { [weak self] continuation in
            let id = UUID()
            self?.continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                self?.continuations.removeValue(forKey: id)
            }
        }
        return stream.makeAsyncIterator()
    }
}

extension DispatchSourceFileSystemObjectObservation: Publisher {
    public typealias Output = DispatchSource.FileSystemEvent
    public typealias Failure = Never
    
    public func receive<S: Subscriber<Output, Failure>>(
        subscriber: S
    ) {
        subject.receive(subscriber: subscriber)
    }
}
