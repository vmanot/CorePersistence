//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public protocol _TypeAssociatedFreeformMetadataValue<Parent> {
    associatedtype Parent
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct _TypeAssociatedFreeformMetadata<Parent>: Initiable {
    private var storage: [_UnsafelySerialized<any _TypeAssociatedFreeformMetadataValue<Parent>.Type>: any _TypeAssociatedFreeformMetadataValue<Parent>] = [:]
    
    public init() {
        
    }
    
    /*public subscript<Value: _TypeAssociatedFreeformMetadataValue<Parent>>(
     _ value: Value.Type
     ) get {
     
     }*/
    
    public mutating func assign<Value: _TypeAssociatedFreeformMetadataValue<Parent>>(
        _ value: Value
    ) {
        let type: any _FreeformMetadataValue<Parent>.Type = Swift.type(of: value)
        let key = _UnsafelySerialized<any _FreeformMetadataValue<Parent>.Type>(type)
        
        storage[key] = value
    }
}

// MARK: - Conformances

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension _TypeAssociatedFreeformMetadata: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        
    }
}
