//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import FoundationX
import Swallow

public final class _ObservableFileURL: ObservableObject, URLConvertible, @unchecked Sendable {
    public typealias AsyncIterator = AnyAsyncIterator<DispatchSource.FileSystemEvent>
    
    private var observation: DispatchSourceFileSystemObjectObservation!
    
    @Published public private(set) var url: URL
    @Published private var bookmark: URL.Bookmark
    
    private let fileIdentifier: FileSystemIdentifier
    
    public init(
        url: URL,
        bookmark: URL.Bookmark?,
        fileIdentifier existingFileIdentifier: FileSystemIdentifier?
    ) throws {
        var _bookmark: URL.Bookmark!
        
        if let bookmark {
            _bookmark = bookmark
        } else {
            try _tryAssert(FileManager.default.fileExists(at: url))
            
            if Thread.isMainThread {
                try MainActor.unsafeAssumeIsolated {
                    _bookmark = try FileManager.default.withUserGrantedAccess(to: url) { url in
                        try URL.Bookmark(for: url)
                    }
                }
            } else {
                _bookmark = try URL.Bookmark(for: url)
            }
        }
        
        if FileManager.default.fileExists(at: url) {
            let fileIdentifier = try FileSystemIdentifier(url: url)
            let bookmarkFileIdentifier = try FileSystemIdentifier(bookmark: _bookmark)
            
            #try(.optimistic) {
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
        
        observation = try DispatchSourceFileSystemObjectObservation(
            filePath: _bookmark.path,
            onEvent: { [weak self] _ in
                let `self` = self
                
                Task { @MainActor in
                    self?._fileDidUpdate()
                }
            }
        )
    }
    
    @MainActor
    public convenience init(url: URL) throws {
        try self.init(url: url, bookmark: nil, fileIdentifier: nil)
    }
    
    @MainActor
    private func _fileDidUpdate() {
        #try(.optimistic) {
            let fileDescriptor = try self.observation.fileDescriptor.unwrap()
            
            var buffer = [UInt8](repeating: 0, count: Int(PATH_MAX))
            
            if fcntl(fileDescriptor, F_GETPATH, &buffer) != -1 {
                let path = String(cString: buffer)
                
                self.bookmark = try URL.Bookmark(for: URL(fileURLWithPath: path))
                self.url = try self.bookmark.toURL()
            }
        }
    }
}

// MARK: - Conformances

extension _ObservableFileURL: AsyncSequence {
    public typealias Element = DispatchSource.FileSystemEvent
    
    public func makeAsyncIterator() -> AsyncIterator {
        AnyAsyncIterator {
            self.observation.makeAsyncIterator()
        }
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
       
        let url: URL? = #try(.optimistic) {
            try container.decodeIfPresent(URL.self, forKey: .url)
        }
        var bookmark: URL.Bookmark? = #try(.optimistic) {
            try container.decodeIfPresent(URL.Bookmark.self, forKey: .bookmark)
        }
        let fileIdentifier: FileSystemIdentifier? = try container.decodeIfPresent(FileSystemIdentifier.self, forKey: .fileIdentifier)
        
        #try(.optimistic) {
            try bookmark?.renew()
        }
        
        let fileURL: URL = try (url ?? (try? bookmark?.toURL())).unwrap()
        
        try self.init(
            url: fileURL,
            bookmark: bookmark,
            fileIdentifier: fileIdentifier
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(bookmark, forKey: .bookmark)
        try container.encode(url, forKey: .url)
    }
}

extension _ObservableFileURL: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileIdentifier)
    }
    
    public static func == (lhs: _ObservableFileURL, rhs: _ObservableFileURL) -> Bool {
        lhs.fileIdentifier == rhs.fileIdentifier
    }
}

extension _ObservableFileURL: Publisher {
    public typealias Output = DispatchSource.FileSystemEvent
    public typealias Failure = Never
    
    public func receive<S: Subscriber<Output, Failure>>(
        subscriber: S
    ) {
        observation.receive(subscriber: subscriber)
    }
}
