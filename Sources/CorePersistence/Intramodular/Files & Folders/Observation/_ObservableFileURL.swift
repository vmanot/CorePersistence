//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import FoundationX
import Swallow

public final class _ObservableFileURL: AsyncSequence, ObservableObject, Publisher, URLConvertible {
    public typealias Output = DispatchSource.FileSystemEvent
    public typealias Failure = Never
    public typealias Element = DispatchSource.FileSystemEvent
    public typealias AsyncIterator = AsyncStream<DispatchSource.FileSystemEvent>.Iterator
    
    private var source: DispatchSourceFileSystemObject?
    private var watchedFileDescriptor: Int32?
    private var subject = PassthroughSubject<DispatchSource.FileSystemEvent, Never>()
    private var continuation: AsyncStream<DispatchSource.FileSystemEvent>.Continuation?
    
    private let fileIdentifier: FileSystemIdentifier
    
    @MainActor
    @Published
    public private(set) var url: URL
    
    @MainActor
    @Published
    private var bookmark: URL.Bookmark
    
    @MainActor(unsafe)
    public init(
        url: URL,
        bookmark: URL.Bookmark?,
        fileIdentifier existingFileIdentifier: FileSystemIdentifier?
    ) throws {
        let _bookmark: URL.Bookmark
        
        if let bookmark {
            _bookmark = bookmark
        } else {
            try _tryAssert(FileManager.default.fileExists(at: url))
            
            _bookmark = try FileManager.default.withUserGrantedAccess(to: url) { url in
                try URL.Bookmark(for: url)
            }
        }
        
        if FileManager.default.fileExists(at: url) {
            let fileIdentifier = try FileSystemIdentifier(url: url)
            let bookmarkFileIdentifier = try FileSystemIdentifier(bookmark: _bookmark)
            
            _expectNoThrow {
                try _tryAssert(fileIdentifier == bookmarkFileIdentifier)
            }
        }
        
        let fileURL: URL = try _bookmark.toURL()
        
        self.bookmark = _bookmark
        self.url = fileURL
        self.fileIdentifier = try FileSystemIdentifier(url: fileURL)
        
        if let existingFileIdentifier {
            try _tryAssert(self.fileIdentifier == existingFileIdentifier)
        }
        
        startWatching()
    }
    
    @MainActor(unsafe)
    public convenience init(url: URL) throws {
        try self.init(url: url, bookmark: nil, fileIdentifier: nil)
    }
    
    deinit {
        stopWatching()
    }
    
    @MainActor
    private func startWatching() {
        do {
            guard let path = try bookmark.path.cString(using: .utf8) else {
                return
            }
            
            let fileDescriptor = open(path, O_EVTONLY)
            
            guard fileDescriptor != -1 else {
                runtimeIssue("Failed to open file descriptor.")
                
                return
            }
            
            watchedFileDescriptor = fileDescriptor
            
            source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: [.write, .rename, .delete, .extend, .attrib], queue: DispatchQueue.global())
            
            source?.setEventHandler { [weak self] in
                guard let self = self else { return }
                let event = self.source?.data ?? []
                self.subject.send(event)
                self.continuation?.yield(event)
                if event.contains(.rename) {
                    Task { @MainActor in
                        self.updateWatchedURL()
                    }
                }
            }
            
            source?.setCancelHandler { [weak self] in
                if let fileDescriptor = self?.watchedFileDescriptor {
                    close(fileDescriptor)
                }
                self?.watchedFileDescriptor = nil
                self?.source = nil
                self?.continuation?.finish()
            }
            
            source?.resume()
        } catch {
            runtimeIssue(error)
        }
    }
    
    public func stopWatching() {
        source?.cancel()
    }
    
    @MainActor
    private func updateWatchedURL() {
        do {
            // Logic to update the URL when the watched file is renamed.
            // This should use a method to resolve the new URL from the file descriptor.
            if let fileDescriptor = watchedFileDescriptor {
                var buffer = [UInt8](repeating: 0, count: Int(PATH_MAX))
                if fcntl(fileDescriptor, F_GETPATH, &buffer) != -1 {
                    let path = String(cString: buffer)
                    self.bookmark = try URL.Bookmark(for: URL(fileURLWithPath: path))
                    self.url = try bookmark.toURL()
                }
            }
        } catch {
            runtimeIssue(error)
        }
    }
    
    public func receive<S>(
        subscriber: S
    ) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        let stream = AsyncStream<DispatchSource.FileSystemEvent> { continuation in
            self.continuation = continuation
            
            Task { @MainActor in
                self.startWatching()
            }
        }
        return stream.makeAsyncIterator()
    }
}

extension _ObservableFileURL: Codable {
    enum CodingKeys: String, CodingKey {
        case url
        case bookmark
        case fileIdentifier
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url: URL? = _expectNoThrow {
            try container.decodeIfPresent(URL.self, forKey: .url)
        }
        var bookmark: URL.Bookmark? = _expectNoThrow {
            try container.decodeIfPresent(URL.Bookmark.self, forKey: .bookmark)
        }
        let fileIdentifier: FileSystemIdentifier? = try container.decodeIfPresent(FileSystemIdentifier.self, forKey: .fileIdentifier)
        
        _expectNoThrow {
            try? bookmark?.renew()
        }
        
        let fileURL: URL = try (url ?? (try? bookmark?.toURL())).unwrap()
        
        try self.init(
            url: fileURL,
            bookmark: bookmark,
            fileIdentifier: fileIdentifier
        )
    }
    
    @MainActor(unsafe)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(bookmark, forKey: .bookmark)
        try container.encode(url, forKey: .url)
    }
}

extension _ObservableFileURL: Hashable {
    @MainActor(unsafe)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileIdentifier)
    }
    
    @MainActor(unsafe)
    public static func == (lhs: _ObservableFileURL, rhs: _ObservableFileURL) -> Bool {
        lhs.fileIdentifier == rhs.fileIdentifier
    }
}

