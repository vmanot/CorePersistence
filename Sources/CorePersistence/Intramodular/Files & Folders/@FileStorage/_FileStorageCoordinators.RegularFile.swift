//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

extension _FileStorageCoordinators {
    public class RegularFile<ValueType, UnwrappedValue>: _AnyFileStorageCoordinator<ValueType, UnwrappedValue> {
        private let cache: any SingleValueCache<UnwrappedValue>
        private var read: (() throws -> UnwrappedValue)!
        private var write: ((UnwrappedValue) throws -> Void)!
        
        private var writeWorkItem: DispatchWorkItem? = nil
        private var valueObjectWillChangeListener: AnyCancellable?
        
        private var _cachedValue: UnwrappedValue? {
            get {
                cache.retrieve()
            } set {
                cache.store(newValue)
                
                setUpObservableObjectObserver()
            }
        }
        
        private var _wasWrappedValueAccessedSynchronously: Bool = false
        
        public var _wrappedValue: UnwrappedValue {
            get throws {
                lock.withCriticalScope {
                    _wasWrappedValueAccessedSynchronously = true
                }
                
                if let value = self._cachedValue {
                    return value
                } else {
                    return try readInitialValue()
                }
            }
        }
        
        public override var wrappedValue: UnwrappedValue {
            get {
                if let value = self._cachedValue {
                    return value
                } else {
                    return try! readInitialValue()
                }
            } set {
                setValue(newValue)
            }
        }
        
        func setValue(_ newValue: UnwrappedValue) {
            objectWillChange.send()
            
            lock.withCriticalScope {
                _cachedValue = newValue
                
                setUpObservableObjectObserver()
            }
            
            objectDidChange.send()
            
            _writeValue(newValue)
        }
        
        @MainActor
        init(
            fileSystemResource: @autoclosure @escaping () throws -> any _FileOrFolderRepresenting,
            configuration: _RelativeFileConfiguration<UnwrappedValue>,
            cache: any SingleValueCache<UnwrappedValue> = InMemorySingleValueCache()
        ) throws {
            assert(configuration.path == nil)
            
            self.cache = cache
            
            try super.init(
                fileSystemResource: try fileSystemResource(),
                configuration: configuration
            )
                                    
            // scheduleEagerRead() // FIXME: !!! disabled because it's maxing out CPU
            
            setUpReadWrite()
            setUpAppRunningStateObserver()
        }
        
        private func setUpReadWrite() {
            var _strongSelf: AnyObject? = self
            
            self.read = { [weak self] () -> UnwrappedValue in
                guard let `self` = self else {
                    assertionFailure()
                    
                    throw Never.Reason.unexpected
                }
                
                _ = _strongSelf
                
                _strongSelf = nil
                
                var result: UnwrappedValue? = try _withLogicalParent(self._enclosingInstance) { () -> UnwrappedValue? in
                    let resource: any _FileOrFolderRepresenting = self.fileSystemResource
                    
                    if let serialization = self.configuration.serialization {
                        guard let decoded: Any = try resource.decode(using: serialization.coder) else {
                            return nil
                        }
                        
                        return try cast(decoded, to: UnwrappedValue.self)
                    } else {
                        return nil // FIXME
                    }
                }
                
                if result == nil {
                    let initialValue = try configuration.serialization?.initialValue().unwrap() ?? _generatePlaceholder(ofType: UnwrappedValue.self)
                    
                    _writeValue(initialValue, immediately: true)
                    
                    result = initialValue
                }
                
                return try result.unwrap()
            }
            
            self.write = { [weak self] newValue in
                guard let `self` = self else {
                    return
                }
                
                try _withLogicalParent(self._enclosingInstance) {
                    if let serialization = self.configuration.serialization {
                        try self.fileSystemResource.encode(
                            newValue,
                            using: serialization.coder
                        )
                    }
                }
            }
        }
        
        private func setUpAppRunningStateObserver() {
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
        
        /// Schedules an eager read of the file into memory.
        private func scheduleEagerRead() {
            let _readInitialValue: (() async -> Void) = {
                _expectNoThrow {
                    _ = try self.readInitialValue()
                }
            }

            Task.detached(priority: .background) {
                try? await Task.sleep(.seconds(1))
                
                let alreadyRead = self.lock.withCriticalScope(perform: { self._wasWrappedValueAccessedSynchronously })
                
                guard !alreadyRead else {
                    return
                }
                
                await Task.yield()
                
                await _readInitialValue()
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
        
        public func readInitialValue() throws -> UnwrappedValue {
            let shouldRead: Bool = lock.withCriticalScope {
                guard !stateFlags.contains(.initialReadComplete) else {
                    return false
                }
                
                return true
            }
            
            guard shouldRead else {
                return self._cachedValue!
            }
            
            let value = try readValueWithRecovery()
            
            lock.withCriticalScope {
                if self._cachedValue == nil {
                    self._cachedValue = value
                }
                
                self.stateFlags += [.initialReadComplete, .latestWritten]
            }
            
            self.objectDidChange.send()
            
            return value
        }
        
        override public func commit() {
            guard !stateFlags.contains(.discarded) else {
                return
            }
            
            guard let value = _cachedValue else {
                _expectNoThrow {
                    if !FileManager.default.fileExists(at: try fileSystemResource._toURL()) {
                        _writeValue(self.wrappedValue, immediately: true)
                    }
                }
                
                return
            }
            
            _writeValue(value, immediately: true)
        }
        
        private func readValueWithRecovery() throws -> UnwrappedValue {
            do {
                let value = try read()
                
                return value
            } catch {
                if let readErrorRecoveryStrategy = configuration.readWriteOptions.readErrorRecoveryStrategy {
                    switch readErrorRecoveryStrategy {
                        case .fatalError:
                            fatalError(error)
                        case .discardAndReset:
                            runtimeIssue(error)
                            
                            if let serialization = configuration.serialization {
                                if let initialValue = try? serialization.initialValue() {
                                    return initialValue
                                }
                            }
                            
                            return try _generatePlaceholder()
                    }
                }
                
                throw error
            }
        }
        
        /// Submit a value to write to the file.
        ///
        /// - Parameters:
        ///   - newValue: The value to write.
        ///   - immediately: Whether the value is written immediately, or is written after a delay.
        private func _writeValue(
            _ newValue: UnwrappedValue,
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
                let isRunningInTest = NSClassFromString("XCTestCase") != nil
                let delay: DispatchTimeInterval
                
                if isRunningInTest {
                    delay = .milliseconds(10)
                } else {
                    delay = .milliseconds(200)
                }
                
                writeQueue.asyncAfter(
                    deadline: .now() + delay,
                    execute: workItem
                )
            }
        }
    }
}
