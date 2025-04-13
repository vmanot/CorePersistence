//
// Copyright (c) Vatsal Manot
//

import FileProvider
import Foundation
import Merge

public struct NSFileProviderReplicatedExtensionCreateOrModifyItemResult {
    public let item: NSFileProviderItem
    public let itemFields: NSFileProviderItemFields
    public let shouldFetchContent: Bool
}

public protocol AsyncNSFileProviderEnumerator: NSFileProviderEnumerator {
    
}

public protocol AsyncNSFileProviderReplicatedExtension: NSObjectProtocol, NSFileProviderReplicatedExtension {
    init(domain: NSFileProviderDomain)
    
    func invalidate()
    
    func enumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest
    ) throws -> any NSFileProviderEnumerator
    
    func item(
        for identifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws -> NSFileProviderItem
    
    func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws -> (URL, NSFileProviderItem)
    
    func createItem(
        basedOn itemTemplate: NSFileProviderItem,
        fields: NSFileProviderItemFields,
        contents url: URL?,
        options: NSFileProviderCreateItemOptions,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws -> NSFileProviderReplicatedExtensionCreateOrModifyItemResult
    
    func modifyItem(
        _ item: NSFileProviderItem,
        baseVersion version: NSFileProviderItemVersion,
        changedFields: NSFileProviderItemFields,
        contents newContents: URL?,
        options: NSFileProviderModifyItemOptions,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws -> NSFileProviderReplicatedExtensionCreateOrModifyItemResult
    
    func deleteItem(
        identifier: NSFileProviderItemIdentifier,
        baseVersion version: NSFileProviderItemVersion,
        options: NSFileProviderDeleteItemOptions,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws
}

@objc
open class AsyncNSFileProviderReplicatedExtensionBase: NSObject, NSFileProviderReplicatedExtension {
    public let domain: NSFileProviderDomain
    
    public required init(domain: NSFileProviderDomain) {
        self.domain = domain
    }
    
    open func invalidate() {
        
    }
    
    public func enumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest
    ) throws -> any NSFileProviderEnumerator {
        let `self` = self as! AsyncNSFileProviderReplicatedExtension
        
        return try self.enumerator(for: containerItemIdentifier, request: request)
    }
    
    public func item(
        for identifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
        _adaptAsyncOperation { context in
            let `self` = self as! AsyncNSFileProviderReplicatedExtension
            
            do {
                let result: NSFileProviderItem? = try await self.item(for: identifier, request: request, progress: context.progress)
                
                await context.willInvokeCompletionHandler()
                
                completionHandler(result, nil)
            } catch {
                await context.willInvokeCompletionHandler()

                completionHandler(nil, error)
            }
        }
    }
    
    public func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        request: NSFileProviderRequest,
        completionHandler: @escaping (URL?, NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
        _adaptAsyncOperation { context in
            let `self` = self as! AsyncNSFileProviderReplicatedExtension

            do {
                let result: (URL, NSFileProviderItem) = try await self.fetchContents(
                    for: itemIdentifier,
                    version: requestedVersion,
                    request: request,
                    progress: context.progress
                )
                
                await context.willInvokeCompletionHandler()

                completionHandler(result.0, result.1, nil)
            } catch {
                await context.willInvokeCompletionHandler()

                completionHandler(nil, nil, error)
            }
        }
    }
    
    public func createItem(
        basedOn itemTemplate: NSFileProviderItem,
        fields: NSFileProviderItemFields,
        contents url: URL?,
        options: NSFileProviderCreateItemOptions = [],
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, (any Error)?) -> Void
    ) -> Progress {
        _adaptAsyncOperation { context in
            let `self` = self as! AsyncNSFileProviderReplicatedExtension

            do {
                let result: NSFileProviderReplicatedExtensionCreateOrModifyItemResult = try await self.createItem(
                    basedOn: itemTemplate,
                    fields: fields,
                    contents: url,
                    options: options,
                    request: request,
                    progress: context.progress
                )
                
                await context.willInvokeCompletionHandler()
                
                completionHandler(result.item, result.itemFields, result.shouldFetchContent, nil)
            } catch {
                await context.willInvokeCompletionHandler()

                completionHandler(nil, .init(), false, error)
            }
        }
    }
    
    public func modifyItem(
        _ item: NSFileProviderItem,
        baseVersion version: NSFileProviderItemVersion,
        changedFields: NSFileProviderItemFields,
        contents newContents: URL?,
        options: NSFileProviderModifyItemOptions = [],
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, (any Error)?) -> Void
    ) -> Progress {
        _adaptAsyncOperation { context in
            let `self` = self as! AsyncNSFileProviderReplicatedExtension

            do {
                let result: NSFileProviderReplicatedExtensionCreateOrModifyItemResult = try await self.modifyItem(
                    item,
                    baseVersion: version,
                    changedFields: changedFields,
                    contents: newContents,
                    options: options,
                    request: request,
                    progress: context.progress
                )
                
                await context.willInvokeCompletionHandler()

                completionHandler(result.item, result.itemFields, result.shouldFetchContent, nil)
            } catch {
                await context.willInvokeCompletionHandler()

                completionHandler(nil, .init(), false, error)
            }
        }
    }
    
    public func deleteItem(
        identifier: NSFileProviderItemIdentifier,
        baseVersion version: NSFileProviderItemVersion,
        options: NSFileProviderDeleteItemOptions = [],
        request: NSFileProviderRequest,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress {
        _adaptAsyncOperation { context in
            let `self` = self as! AsyncNSFileProviderReplicatedExtension
            
            do {
                try await self.deleteItem(
                    identifier: identifier,
                    baseVersion: version,
                    options: options,
                    request: request,
                    progress: context.progress
                )
                
                await context.willInvokeCompletionHandler()

                completionHandler(nil)
            } catch {
                await context.willInvokeCompletionHandler()

                completionHandler(error)
            }
        }
    }
    
    private struct _AsyncToNonAsyncAdapterContext {
        /// A promise of an _optional_ progress that the async function should fulfill so that it can allow the synchronous function to exit.
        /// If this promise is fulfilled with a `nil`, a default `Progress` is constructed automatically.
        let progress: _AsyncPromise<Progress?, Never>
        /// To be called by the async function before it invokes the `completionHandler`, giving a chance for a default `Progress` (if it was constructed) to be marked as completed. The `Progress` must be `1.0` before the `completionHandler` is invoked, which is why this is needed.
        let willInvokeCompletionHandler: () async -> Void
    }
    
    private func _adaptAsyncOperation(
        operation: @escaping (_AsyncToNonAsyncAdapterContext) async -> Void
    ) -> Progress {
        let progress = _AsyncPromise<Progress?, Never>()
        let defaultProgress: Progress = Progress(totalUnitCount: 1)
        
        Task<Void, Never> { () -> Void in
            func willInvokeCompletionHandler() async {
                defaultProgress.totalUnitCount += 1
            }
            
            await operation(
                _AsyncToNonAsyncAdapterContext(
                    progress: progress,
                    willInvokeCompletionHandler: willInvokeCompletionHandler
                )
            )
        }
        
        return progress._noasync_result().get() ?? defaultProgress
    }
}

final class ExampleAsyncNSFileProviderReplicatedExtension: AsyncNSFileProviderReplicatedExtensionBase, AsyncNSFileProviderReplicatedExtension {
    func enumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest
    ) throws -> any AsyncNSFileProviderEnumerator {
        fatalError()
    }
    
    func item(
        for identifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws -> NSFileProviderItem {
        fatalError()
    }
    
    func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws -> (URL, NSFileProviderItem) {
        fatalError()
    }
    
    func createItem(
        basedOn itemTemplate: NSFileProviderItem,
        fields: NSFileProviderItemFields,
        contents url: URL?,
        options: NSFileProviderCreateItemOptions,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws -> NSFileProviderReplicatedExtensionCreateOrModifyItemResult {
        fatalError()
    }
    
    func modifyItem(
        _ item: NSFileProviderItem,
        baseVersion version: NSFileProviderItemVersion,
        changedFields: NSFileProviderItemFields,
        contents newContents: URL?,
        options: NSFileProviderModifyItemOptions,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws -> NSFileProviderReplicatedExtensionCreateOrModifyItemResult {
        fatalError()
    }
    
    func deleteItem(
        identifier: NSFileProviderItemIdentifier,
        baseVersion version: NSFileProviderItemVersion,
        options: NSFileProviderDeleteItemOptions,
        request: NSFileProviderRequest,
        progress: _AsyncPromise<Progress?, Never>
    ) async throws {
        fatalError()
    }
}
