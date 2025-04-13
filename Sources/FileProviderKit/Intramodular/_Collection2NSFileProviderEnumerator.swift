//
// Copyright (c) Vatsal Manot
//

import FileProvider
import Foundation
import Merge

@available(macOS 11.0, *)
public class _CollectionToNSFileProviderEnumeratorAdapter<Collection: RandomAccessCollection>: NSObject, NSFileProviderEnumerator where Collection.Element: NSFileProviderItemProtocol {
    /// Defines the paging behavior for the enumerator
    public enum PagingStrategy {
        /// Use a specific page size (will be adjusted based on system recommendations)
        case paged(defaultSize: Int)
        /// Return all items at once, ignoring pagination
        case allItems
    }
    
    private let collection: Collection
    private let pagingStrategy: PagingStrategy
    private var currentSyncAnchorValue: Data
    
    /// Initialize with a collection of items that conform to NSFileProviderItemProtocol
    /// - Parameters:
    ///   - collection: The source collection to enumerate
    ///   - pagingStrategy: The strategy to use for paging (.paged or .allItems)
    public init(collection: Collection, pagingStrategy: PagingStrategy = .paged(defaultSize: 50)) {
        self.collection = collection
        self.pagingStrategy = pagingStrategy
        self.currentSyncAnchorValue = UUID().uuidString.data(using: .utf8) ?? Data()
        
        super.init()
    }
    
    public func invalidate() {
        
    }
    
    public func enumerateItems(
        for observer: NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {
        switch pagingStrategy {
            case .allItems:
                // Return all items at once without pagination
                if collection.isEmpty {
                    observer.finishEnumerating(upTo: nil)
                    return
                }
                
                // Send all items at once
                observer.didEnumerate(Array(collection))
                observer.finishEnumerating(upTo: nil)
                
            case .paged(let defaultSize):
                // Get suggested page size from the system or fallback to the default
                let suggestedSize = observer.suggestedPageSize ?? defaultSize
                let actualPageSize = min(suggestedSize, 100 * suggestedSize) // System enforces max of 100x suggested size
                
                // Decode the page data to determine the starting index
                let startIndex: Collection.Index
                
                if page == NSFileProviderPage(NSFileProviderPage.initialPageSortedByName as Data) ||
                    page == NSFileProviderPage(NSFileProviderPage.initialPageSortedByDate as Data) {
                    // Start from the beginning for initial pages
                    startIndex = collection.startIndex
                } else {
                    // Parse the page data to get the stored index
                    if let indexOffset = Int(String(data: page.rawValue, encoding: .utf8) ?? "0"),
                       indexOffset < collection.count {
                        startIndex = collection.index(collection.startIndex, offsetBy: indexOffset)
                    } else {
                        // Invalid page, start from beginning
                        startIndex = collection.startIndex
                    }
                }
                
                // Calculate the end index for this page
                let remainingItems = collection.distance(from: startIndex, to: collection.endIndex)
                let itemsToEnumerate = min(actualPageSize, remainingItems)
                
                if itemsToEnumerate <= 0 {
                    // No items to enumerate
                    observer.finishEnumerating(upTo: nil)
                    return
                }
                
                let endIndex = collection.index(startIndex, offsetBy: itemsToEnumerate)
                
                // Extract the items for this page
                let pageItems = collection[startIndex..<endIndex]
                
                // Create the next page reference if there are more items
                let nextPage: NSFileProviderPage?
                if endIndex != collection.endIndex {
                    let nextOffset = collection.distance(from: collection.startIndex, to: endIndex)
                    if let nextPageData = String(nextOffset).data(using: .utf8) {
                        nextPage = NSFileProviderPage(nextPageData)
                    } else {
                        nextPage = nil
                    }
                } else {
                    nextPage = nil
                }
                
                // Send the items to the observer
                observer.didEnumerate(Array(pageItems))
                observer.finishEnumerating(upTo: nextPage)
        }
    }
    
    public func enumerateChanges(
        for observer: NSFileProviderChangeObserver,
        from syncAnchor: NSFileProviderSyncAnchor
    ) {
        // For a static collection, we only enumerate all items on the first sync
        // and report no changes thereafter
        
        if syncAnchor.rawValue.isEmpty || syncAnchor.rawValue != currentSyncAnchorValue {
            // This is the first sync or the anchor has changed
            // Report all items as "updated"
            
            switch pagingStrategy {
                case .allItems:
                    // Send all items at once
                    if !collection.isEmpty {
                        observer.didUpdate(Array(collection))
                    }
                    observer.finishEnumeratingChanges(upTo: NSFileProviderSyncAnchor(currentSyncAnchorValue), moreComing: false)
                    
                case .paged:
                    // Handle batched updates based on system recommendations
                    let batchSize = observer.suggestedBatchSize ?? collection.count
                    let actualBatchSize = min(batchSize, 100 * batchSize) // System enforces max of 100x suggested size
                    
                    // Send all items in batches if needed
                    var currentIndex = collection.startIndex
                    var moreComing = true
                    
                    while currentIndex < collection.endIndex && moreComing {
                        let remainingCount = collection.distance(from: currentIndex, to: collection.endIndex)
                        let itemsInBatch = min(actualBatchSize, remainingCount)
                        
                        if itemsInBatch <= 0 {
                            break
                        }
                        
                        let batchEndIndex = collection.index(currentIndex, offsetBy: itemsInBatch)
                        let batchItems = collection[currentIndex..<batchEndIndex]
                        
                        // Send the batch
                        observer.didUpdate(Array(batchItems))
                        
                        // Update for next iteration
                        currentIndex = batchEndIndex
                        moreComing = currentIndex < collection.endIndex
                        
                        // If we're at the end, finish with no more coming
                        if !moreComing {
                            observer.finishEnumeratingChanges(
                                upTo: NSFileProviderSyncAnchor(currentSyncAnchorValue),
                                moreComing: false
                            )
                        }
                    }
            }
        } else {
            observer.finishEnumeratingChanges(
                upTo: NSFileProviderSyncAnchor(currentSyncAnchorValue),
                moreComing: false
            )
        }
    }
    
    public func currentSyncAnchor(
        completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void
    ) {
        // For a static collection, we can use a fixed sync anchor
        completionHandler(NSFileProviderSyncAnchor(currentSyncAnchorValue))
    }
    
    /// Update the collection and signal that changes should be enumerated
    /// - Parameter newCollection: The new collection to enumerate
    /// - Note: This method is only provided as a convenience for testing,
    ///         as the class is designed primarily for static collections
    public func updateCollection(
        _ newCollection: Collection
    ) {
        // This method would typically be used in a mutable implementation
        // Here we just generate a new sync anchor
        currentSyncAnchorValue = UUID().uuidString.data(using: .utf8) ?? Data()
    }
}
