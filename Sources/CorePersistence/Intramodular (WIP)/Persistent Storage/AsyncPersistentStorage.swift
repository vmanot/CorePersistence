//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Runtime
import Swallow

public protocol AsyncPersistentStorageProjectionElement<Value> {
    associatedtype Value
    associatedtype ValuesPublisher: Publisher<Value, Never> where ValuesPublisher.Output == Value, ValuesPublisher.Failure == Never // FIXME: Allow errors
    
    var upstreamValuesPublisher: ValuesPublisher { get }
    
    func send(_ value: Value) async
}

@propertyWrapper
public final class AsyncPersistentStorage<WrappedValue, ProjectedValue>: ObservableObject, PropertyWrapper {
    private var base: any _AsyncPersistentStorageBase<WrappedValue, ProjectedValue>
    private let objectWillChangeRelay = ObjectWillChangePublisherRelay()
        
    public var objectWillChange: AnyObjectWillChangePublisher {
        base.eraseObjectWillChangePublisher()
    }
    
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance enclosingInstance: EnclosingSelf,
        wrapped wrappedKeyPath: KeyPath<EnclosingSelf, WrappedValue>,
        storage storageKeyPath: KeyPath<EnclosingSelf, AsyncPersistentStorage>
    ) -> WrappedValue {
        let propertyWrapper = enclosingInstance[keyPath: storageKeyPath]
        
        propertyWrapper.objectWillChangeRelay.source = propertyWrapper
        propertyWrapper.objectWillChangeRelay.destination = enclosingInstance
        
        return propertyWrapper.wrappedValue
    }
        
    public var wrappedValue: WrappedValue {
        get {
            base.wrappedValue
        }
    }
    
    init<Base: _AsyncPersistentStorageBase<WrappedValue, ProjectedValue>>(
        base: Base
    ) {
        self.base = base
    }
}
