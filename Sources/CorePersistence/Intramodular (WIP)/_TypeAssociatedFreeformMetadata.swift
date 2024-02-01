//
// Copyright (c) Vatsal Manot
//

import _ModularDecodingEncoding
import Combine
import Swallow

public protocol _TypeAssociatedFreeformMetadataValue<Parent>: HadeanIdentifiable {
    associatedtype Parent
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct _TypeAssociatedFreeformMetadata<Parent>: Initiable {
    typealias StorageKey = _UnsafelySerialized<any _TypeAssociatedFreeformMetadataValue<Parent>.Type>
    
    private var storage: [StorageKey: any _TypeAssociatedFreeformMetadataValue<Parent>] = [:]
    
    public init() {
        
    }
    
    public subscript<Value: _TypeAssociatedFreeformMetadataValue<Parent>>(
        _ type: Value.Type
    ) -> Value? {
        get {
            storage[_key(fromType: type)].map({ $0 as! Value })
        } set {
            storage[_key(fromType: type)] = newValue
        }
    }
    
    public mutating func assign<Value: _TypeAssociatedFreeformMetadataValue<Parent>>(
        _ value: Value
    ) {
        storage[_key(fromType: Swift.type(of: value))] = value
    }
    
    private func _key<Value: _TypeAssociatedFreeformMetadataValue<Parent>>(
        fromType type: Value.Type
    ) -> StorageKey {
        StorageKey(type)
    }
}

// MARK: - Conformances

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension _TypeAssociatedFreeformMetadata: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        
    }
}
