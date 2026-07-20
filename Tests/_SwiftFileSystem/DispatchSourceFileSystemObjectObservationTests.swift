//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Foundation
@testable import _SwiftFileSystem
import Testing

@Suite("DispatchSourceFileSystemObject.Observation")
struct DispatchSourceFileSystemObjectObservationTests {
    @Test("The default callback runs on the main queue")
    @MainActor
    func defaultCallbackRunsOnMainQueue() async throws {
        let fileURL = try makeTemporaryFile()
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        let (events, eventContinuation) = AsyncStream<Bool>.makeStream()
        defer {
            eventContinuation.finish()
        }

        let observation = try DispatchSourceFileSystemObject.Observation(
            filePath: fileURL.path
        ) { _ in
            #expect(Thread.isMainThread)
            MainActor.preconditionIsolated()
            eventContinuation.yield(true)
        }

        try appendToFile(at: fileURL)

        var iterator = events.makeAsyncIterator()
        let event = await iterator.next()

        #expect(event == true)

        withExtendedLifetime(observation) {}
    }

    @Test("The callback runs on a supplied queue")
    func callbackRunsOnSuppliedQueue() async throws {
        let fileURL = try makeTemporaryFile()
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        let queue = DispatchQueue(label: "DispatchSourceFileSystemObjectObservationTests.callback")
        let queueKey = DispatchSpecificKey<Bool>()
        queue.setSpecific(key: queueKey, value: true)

        let (events, eventContinuation) = AsyncStream<Bool>.makeStream()
        defer {
            eventContinuation.finish()
        }

        let observation = try DispatchSourceFileSystemObject.Observation(
            filePath: fileURL.path,
            queue: queue
        ) { _ in
            #expect(DispatchQueue.getSpecific(key: queueKey) == true)
            eventContinuation.yield(true)
        }

        try appendToFile(at: fileURL)

        var iterator = events.makeAsyncIterator()
        let event = await iterator.next()

        #expect(event == true)

        withExtendedLifetime(observation) {}
    }

    private func makeTemporaryFile() throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("log")

        guard FileManager.default.createFile(atPath: fileURL.path, contents: Data()) else {
            throw CocoaError(.fileWriteUnknown)
        }

        return fileURL
    }

    private func appendToFile(at fileURL: URL) throws {
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        defer {
            try? fileHandle.close()
        }

        try fileHandle.seekToEnd()
        try fileHandle.write(contentsOf: Data("event\n".utf8))
        try fileHandle.synchronize()
    }
}
