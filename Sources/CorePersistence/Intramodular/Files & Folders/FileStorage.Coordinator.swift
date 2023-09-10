//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

extension FileStorage {
    public typealias Coordinator = _FileStorageCoordinator<Value>
}

public class _FileStorageCoordinator<Value>: ObservableObject, @unchecked Sendable {
    enum StateFlag {
        case initialReadComplete
        case latestWritten
    }
    
    private let cancellables = Cancellables()
    private let lock = OSUnfairLock()
    
    private let writeQueue = DispatchQueue(
        label: "com.vmanot.Data.FileStorage.Coordinator.write",
        qos: .default
    )
    
    let configuration: _RelativeFileConfiguration<Value>
    
    private var file: any _FileOrFolderRepresenting
    private let cache: any SingleValueCache<Value>
    private var read: (() throws -> Value)!
    private var write: ((Value) throws -> Void)!
    
    private var stateFlags: Set<StateFlag> = []
    
    private var writeWorkItem: DispatchWorkItem? = nil
    private var valueObjectWillChangeListener: AnyCancellable?
    
    private var _cachedValue: Value? {
        get {
            cache.retrieve()
        } set {
            cache.store(newValue)
            
            setUpObservableObjectObserver()
        }
    }
    
    private func setUpObservableObjectObserver() {
        guard let value = _cachedValue as? (any ObservableObject) else {
            return
        }
        
        let objectWillChange = (value.objectWillChange as any Publisher)._eraseToAnyPublisherAnyOutputAnyError()
        
        valueObjectWillChangeListener?.cancel()
        valueObjectWillChangeListener = objectWillChange
            .stopExecutionOnError()
            .mapTo(())
            .sink { [weak self] in
                guard let `self` = self, let value = self._cachedValue else {
                    return assertionFailure()
                }
                
                self.objectWillChange.send()
                
                lock.withCriticalScope {
                    self.stateFlags.remove(.latestWritten)
                }
                
                self._writeValue(value)
            }
    }
    
    var value: Value {
        get {
            if let value = self._cachedValue {
                return value
            } else {
                return readInitialValue()
            }
        } set {
            setValue(newValue)
        }
    }
    
    func setValue(_ newValue: Value) {
        objectWillChange.send()
        
        lock.withCriticalScope {
            _cachedValue = newValue
            
            setUpObservableObjectObserver()
        }
        
        _writeValue(newValue)
    }
    
    init(
        file: any _FileOrFolderRepresenting,
        configuration: _RelativeFileConfiguration<Value>,
        cache: any SingleValueCache<Value>
    ) {
        self.file = file
        self.configuration = configuration
        self.cache = cache
        self.read = {
            guard let contents = try file.decode(using: configuration.serialization.coder) else {
                return try configuration.serialization.initialValue().unwrap()
            }
            
            return try cast(contents, to: Value.self)
        }
        self.write = { [weak self] in
            try self?.file.encode($0, using: configuration.serialization.coder)
        }
        
        Task.detached(priority: .high) { [weak self] in
            self?.readInitialValue()
        }
        
        AppRunningState.EventNotificationPublisher()
            .sink { [unowned self] event in
                guard lock.withCriticalScope({ !self.stateFlags.contains(.latestWritten) }) else {
                    return
                }
                
                switch event {
                    case .willBecomeInactive:
                        commit()
                    default:
                        break
                }
            }
            .store(in: cancellables)
    }
    
    convenience init(
        initialValue: Value?,
        file: any _FileOrFolderRepresenting,
        coder: _AnyConfiguredFileCoder,
        options: FileStorage<Value>.Options
    ) {
        self.init(
            file: file,
            configuration: .init(
                path: nil,
                coder: coder,
                readWriteOptions: options,
                initialValue: initialValue
            ),
            cache: InMemorySingleValueCache()
        )
    }
    
    public func readInitialValue() -> Value {
        let shouldRead: Bool = lock.withCriticalScope {
            guard !stateFlags.contains(.initialReadComplete) else {
                return false
            }
            
            return true
        }
        
        guard shouldRead else {
            return self._cachedValue!
        }
        
        let value = try! readValueWithRecovery()
        
        lock.withCriticalScope {
            if self._cachedValue == nil {
                self._cachedValue = value
            }
            
            self.stateFlags += [.initialReadComplete, .latestWritten]
        }
        
        return value
    }
    
    public func commit() {
        guard let value = _cachedValue else {
            return
        }
        
        _writeValue(value, immediately: true)
    }
    
    private func readValueWithRecovery() throws -> Value {
        do {
            let value = try read()
            
            return value
        } catch {
            switch configuration.readWriteOptions.readErrorRecoveryStrategy {
                case .fatalError:
                    fatalError(error)
                case .discardAndReset:
                    runtimeIssue(error)
                    
                    // Breakpoint.trigger()
                    
                    return try configuration.serialization.initialValue().unwrap()
            }
        }
    }
    
    /// Submit a value to write to the file.
    ///
    /// - Parameters:
    ///   - newValue: The value to write.
    ///   - immediately: Whether the value is written immediately, or is written after a delay.
    private func _writeValue(
        _ newValue: Value,
        immediately: Bool = false
    ) {
        func _writeValueUnconditionally() {
            try! self.write(newValue)
            
            lock.withCriticalScope {
                stateFlags.insert(.latestWritten)
            }
        }
        
        let workItem = DispatchWorkItem(qos: .default, block: _writeValueUnconditionally)
        
        lock.withCriticalScope {
            self.writeWorkItem?.cancel()
            self.writeWorkItem = workItem
        }
        
        if immediately {
            _writeValueUnconditionally()
        } else {
            writeQueue.asyncAfter(deadline: .now() + .milliseconds(400), execute: workItem)
        }
    }
    
    deinit {
        commit()
    }
}
