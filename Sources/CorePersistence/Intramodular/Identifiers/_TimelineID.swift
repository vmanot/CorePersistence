//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct _TimelineID<T: UniversallyUniqueIdentifier>: Sendable {
    public let rawValue: UUID
    
    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

extension _TimelineID: Codable where T: Codable {
    
}

extension _TimelineID: Equatable where T: Equatable {
    
}

extension _TimelineID: Hashable where T: Hashable {
    
}

extension _TimelineID: Initiable where T: Initiable {
    public init() {
        self.init(rawValue: .init())
    }
}

public final class TimelineNode<T: Initiable & UniversallyUniqueIdentifier> {
    public typealias Element = _TimelineID<T>

    public let id: Element
    public let parent: TimelineNode?
    public var children: [TimelineNode]
    
    init(parent: TimelineNode?) {
        self.id = Element()
        self.parent = parent
        self.children = []
    }
    
    public convenience init() {
        self.init(parent: nil)
    }
    
    public convenience init(parent: TimelineNode) {
        self.init(parent: Optional(parent))
    }

    public func fork() -> TimelineNode {
        let child = TimelineNode(parent: self)
        
        children.append(child)
        
        return child
    }
    
    public func getPath() -> _TimelinePath<T> {
        var path: [TimelineNode] = []
        var currentNode: TimelineNode? = self
        while let node = currentNode {
            path.append(node)
            currentNode = node.parent
        }
        return _TimelinePath(timelineIDs: path.reversed().map({ $0.id }))
    }
}

public struct _TimelinePath<T: Initiable & UniversallyUniqueIdentifier & Sendable>: Hashable, Sendable {
    public typealias Element = _TimelineID<T>
    
    private var timelineIDs: [Element]
    
    public init(timelineIDs: [Element]) {
        self.timelineIDs = timelineIDs
    }
    
    public func appending(_ element: Element) -> Self {
        guard tip != element else {
            return self
        }
        
        return .init(timelineIDs: timelineIDs.appending(element))
    }
    
    public var tip: Element {
        timelineIDs.last!
    }
    
    public init(first: Element) {
        self.init(timelineIDs: [first])
    }
    
    public func belongs(to path: _TimelinePath<T>) -> Bool {
        path.timelineIDs == path.timelineIDs || path.timelineIDs.hasPrefix(timelineIDs)
    }
    
    public func contains(_ path: _TimelinePath<T>) -> Bool {
        path.belongs(to: self)
    }
}

extension _TimelinePath: Sequence {
    public func makeIterator() -> AnyIterator<Element> {
        .init(timelineIDs.makeIterator())
    }
}
