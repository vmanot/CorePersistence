//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Runtime
import Swallow

extension _FileStorageCoordinators {
    public class RegularFile<ValueType, UnwrappedValue>: _AnyFileStorageCoordinator<ValueType, UnwrappedValue>, @unchecked Sendable {
        public enum Tasks {
            case read
            case write
        }
        
        private let tasks = KeyedThrowingTaskGroup<Tasks>()
        private let cache: any SingleValueCache<UnwrappedValue>
        private var read: (() throws -> UnwrappedValue)!
        private var write: ((UnwrappedValue) throws -> Void)!
        
        private var writeWorkItem: DispatchWorkItem? = nil
        private var valueObjectWillChangeListener: AnyCancellable?
        private var _fakeObservationTrackedValue = _RuntimeConditionalObservationTrackedValue<Void>(wrappedValue: ())
        private var __ContinuousObservationTrackingSubscription: _ContinuousObservationTrackingSubscription?
        
        private var _cachedValue: UnwrappedValue? {
            get {
                cache.retrieve()
            } set {
                cache.store(newValue)
                
                _didInitializeOrDidSetCachedValue(value: newValue)
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
                _fakeObservationTrackedValue.notifyingObservationRegistrar(.accessOnly) {
                    if let value = self._cachedValue {
                        return value
                    } else {
                        return try! readInitialValue()
                    }
                }
            } set {
                _fakeObservationTrackedValue.notifyingObservationRegistrar(.mutation) {
                    defer {
                        stateFlags.insert(.didWriteOnce)
                    }
                    
                    setValue(newValue)
                }
            }
        }
        
        init(
            fileSystemResource: @escaping () throws -> any _FileOrFolderRepresenting,
            configuration: _RelativeFileConfiguration<UnwrappedValue>,
            cache: any SingleValueCache<UnwrappedValue> = InMemorySingleValueCache()
        ) throws {
            assert(configuration.path == nil)
            
            self.cache = cache
            
            try super.init(
                fileSystemResource: try fileSystemResource(),
                configuration: configuration
            )
            
            Task.detached(priority: .userInitiated) { @MainActor () -> Void in
                do {
                    await Task.yield()
                    
                    let url: URL = try self.fileSystemResource._toURL()
                    
                    if !FileManager.default.fileExists(at: url) {
                        _ = try FileManager.default.fileExists(at: _AnyUserPermittedURL(url)._toURL())
                    }
                } catch CanonicalFileDirectory.Error.directoryNotSpecified {
                    return
                } catch {
                    throw error
                }
            }
            // scheduleEagerRead() // FIXME: !!! disabled because it's maxing out CPU
            
            setUpReadWriteClosures()
            setUpAppRunningStateObserver()
        }
        
        override public var wantsCommit: Bool {
            guard !stateFlags.contains(.discarded) else {
                return false
            }
            
            if !stateFlags.contains(.didWriteOnce) {
                return true
            }
            
            guard stateFlags.contains(.latestWritten) else {
                return true
            }
            
            return true
        }
        
        override public func commitUnconditionally() {
            assert((try? self.fileSystemResource) != nil)

            guard let value = _cachedValue else {
                #try(.optimistic) {
                    if !FileManager.default.fileExists(at: try self.fileSystemResource._toURL()) {
                        self._writeValue(self.wrappedValue, immediately: true)
                    }
                }
                
                return
            }
            
            _writeValue(value, immediately: true)
        }
        
        private func _didInitializeOrDidSetCachedValue(value: UnwrappedValue?) {
            _setUpObservableObjectObserver()
            _setUpObservationTrackingIfNecessary(value: value)
        }
        
        private func _setUpObservationTrackingIfNecessary(value: UnwrappedValue?) {
            guard #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *), let value: any Observable = value as? (any Observable) else {
                __ContinuousObservationTrackingSubscription?.cancel()
                __ContinuousObservationTrackingSubscription = nil

                return
            }
            
            __ContinuousObservationTrackingSubscription = _withContinuousObservationTrackingIfAvailable {
                value._accessAllKeyPathsIfTypeIsKeyPathIterable()
            } onChange: { [weak self] in
                self?._markDirty()
            }
        }
        
        private func _markDirty() {
            lock.withCriticalScope {
                self.stateFlags.remove(.latestWritten)
            }
        }
    }
}

extension _FileStorageCoordinators.RegularFile {
    func setValue(
        _ newValue: UnwrappedValue
    ) {
        if !swift_isClassType(_getUnwrappedType(ofValue: newValue)) {
            if AnyEquatable.equate(newValue, _cachedValue) == true {
                return
            }
        }
        
        objectWillChange.send()
        
        lock.withCriticalScope {
            _cachedValue = newValue
        }
        
        objectDidChange.send()
        
        _writeValue(newValue)
    }
    
    private func setUpReadWriteClosures() {
        var _strongSelf: AnyObject? = self
        
        self.read = { [weak self] () -> UnwrappedValue in
            guard let `self` = self else {
                assertionFailure()
                
                throw Never.Reason.unexpected
            }
            
            _ = _strongSelf
            
            _strongSelf = nil
            
            var result: UnwrappedValue? = try _withLogicalParent(self._enclosingInstance) { () -> UnwrappedValue? in
                let resource: any _FileOrFolderRepresenting = try self.fileSystemResource
                
                if let serialization: _FileOrFolderSerializationConfiguration<UnwrappedValue> = self.configuration.serialization {
                    guard let decoded: Any = try? resource.decode(using: serialization.coder) else {
                        guard let decoded: Any = try _AnyUserPermittedURL(resource._toURL()).decode(using: serialization.coder) else {
                            return nil
                        }
                        
                        return try cast(decoded, to: UnwrappedValue.self)
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
                    var resource = try self.fileSystemResource
                    
                    try resource.encode(
                        newValue,
                        using: serialization.coder
                    )
                    
                    self.setFileSystemResource(resource)
                }
            }
        }
    }
    
    private func setUpAppRunningStateObserver() {
        AppRunningState.EventNotificationPublisher()
            .sink { [unowned self] event in
                let latestWritten: Bool = lock.withCriticalScope({ self.stateFlags.contains(.latestWritten) })
                
                guard !latestWritten else {
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
            #try(.optimistic) {
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
    
    private func _setUpObservableObjectObserver() {
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
            return try self._cachedValue.forceUnwrap()
        }
        
        let value: UnwrappedValue = try _readValueWithRecovery()
        
        lock.withCriticalScope {
            if self._cachedValue == nil {
                self._cachedValue = value
            }
            
            self.stateFlags += [.initialReadComplete, .latestWritten]
        }
        
        self.objectDidChange.send()
        
        return value
    }
    
    private func _readValueWithRecovery() throws -> UnwrappedValue {
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
        @Sendable
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
            
            do {
                try tasks.insert(.write, policy: .discardPrevious) {
                    try? await Task.sleep(delay)
                    
                    _writeValueUnconditionally()
                }
            } catch {
                runtimeIssue(error)
            }
        }
    }
}
