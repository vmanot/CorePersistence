//
// Copyright (c) Vatsal Manot
//

import Foundation
import Dispatch
import Merge
import Swallow
import System

@available(*, deprecated, renamed: "_DirectoryOrFileEventPublisher", message: "_DirectoryEventPublisher has been renamed to _DirectoryOrFileEventPublisher")
public typealias _DirectoryEventPublisher = _DirectoryOrFileEventPublisher

public final class _DirectoryOrFileEventPublisher: Cancellable, ConnectablePublisher {
    public typealias Output = Void
    public typealias Failure = Error

    public let url: URL
    public let filePath: FilePath
    
    private let queue: DispatchQueue
    private let eventsPublisher = PassthroughSubject<Void, Error>()
    private var fileDescriptor: FileDescriptor?
    private var source: DispatchSourceProtocol?
    
    private var lastContentsSnapshot: Set<URL>?
    private var lastFileModificationDate: Date?
    private var lastFileSize: UInt64?

    
    private var isDirectory: Bool {
        return FileManager.default.isDirectory(at: url)
    }
    
    public init(url: URL, queue: DispatchQueue?) throws {
        self.url = url
        self.queue = queue ?? DispatchQueue.global(qos: .utility)
        self.filePath = try FilePath(url: url).unwrap()
        
        refreshSnapshot()
    }
    
    /// Starts monitoring the directory for changes.
    ///
    /// - Throws: An error if the file descriptor cannot be opened.
    public func start() throws {
        guard fileDescriptor == nil || source == nil else {
            assert(fileDescriptor == nil && source == nil)
            
            return
        }
        
        let fileDescriptor = try FileDescriptor.open(filePath, .init(rawValue: O_EVTONLY))
        
        self.fileDescriptor = fileDescriptor
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor.rawValue,
            eventMask: [.write, .rename, .delete],
            queue: queue
        )
        
        self.source = source
        
        source.setEventHandler { [weak self] in
            guard let `self` = self else {
                return 
            }
            
            guard self.contentsAreDirty() else {
                return
            }
             
            self.eventsPublisher.send(())
        }
        
        source.setCancelHandler { [weak self] in
            self?.cancel()
        }
        
        source.resume()
    }
    
    /// Cancels the monitoring of the directory.
    public func cancel()  {
        guard let source, let fileDescriptor else {
            return
        }
        
        self.source = nil
        self.fileDescriptor = nil
        
        do {
            source.cancel()
            
            try fileDescriptor.close()
            
            self.eventsPublisher.send(completion: .finished)
        } catch {
            assertionFailure()
            
            self.eventsPublisher.send(completion: .failure(error))
        }
    }
    
    private func refreshSnapshot() {
        if isDirectory {
            do {
                lastContentsSnapshot = try Set(FileManager.default.contentsOfDirectory(at: url))
            } catch {
                assertionFailure(error)
                lastContentsSnapshot = nil
            }
        } else {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                lastFileModificationDate = attributes[.modificationDate] as? Date
                lastFileSize = attributes[.size] as? UInt64
            } catch {
                lastFileModificationDate = nil
                lastFileSize = nil
            }
        }
    }

    
    private func contentsAreDirty() -> Bool {
        
        let lastSnapshot = lastContentsSnapshot
        let lastModificationDate = lastFileModificationDate
        let lastSize = lastFileSize
        
        refreshSnapshot()
        
        if isDirectory {
            return lastSnapshot != lastContentsSnapshot
        } else {
            return lastModificationDate != lastFileModificationDate || lastSize != lastFileSize
        }
    }

    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Void, S.Failure == Error {
        eventsPublisher.receive(subscriber: subscriber)
    }
    
    public func connect() -> Cancellable {
        do {
            _ = try start()
        } catch {
            eventsPublisher.send(completion: .failure(error))
        }
        
        return self
    }
}
