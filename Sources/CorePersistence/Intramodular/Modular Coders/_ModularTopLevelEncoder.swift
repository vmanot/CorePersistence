//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public struct _ModularTopLevelEncoder<Output>: TopLevelEncoder, @unchecked Sendable {
    private let base: AnyTopLevelEncoder<Output>
    private var configuration: _ModularEncoder.Configuration
    
    public var plugins: [any _ModularCodingPlugin] {
        get {
            configuration.plugins
        } set {
            configuration.plugins = newValue
        }
    }
    
    public init<Encoder: TopLevelEncoder>(from encoder: Encoder) where Encoder.Output == Output {
        self.base = AnyTopLevelEncoder(erasing: encoder)
        self.configuration = .init()
    }
    
    public func encode<T>(_ value: T) throws -> Output  {
        if let value = value as? _ModularTopLevelProxyEncodableType {
            return try base.encode(value)
        } else {
            return try base.encode(
                _ModularEncoder.TopLevelProxyEncodable<T>(
                    base: value,
                    encoderConfiguration: configuration
                )
            )
        }
    }
}

protocol _ModularTopLevelProxyEncodableType: Encodable {
    
}

extension _ModularEncoder {
    final class TopLevelProxyEncodable<Value>: _ModularTopLevelProxyEncodableType {
        private let base: Value
        private let isBaseUnwrapped: Bool?
        private let encoderConfiguration: _ModularEncoder.Configuration
        
        init(base: Value, isBaseUnwrapped: Bool? = nil, encoderConfiguration: _ModularEncoder.Configuration) {
            self.base = base
            self.isBaseUnwrapped = isBaseUnwrapped
            self.encoderConfiguration = encoderConfiguration
        }
        
        func encode(to encoder: Encoder) throws {
            assert(!(base is _ModularTopLevelProxyEncodableType))
            assert(!(encoder is _ModularEncoder))
            
            let wrappedEncoder = _ModularEncoder(
                base: encoder,
                configuration: encoderConfiguration,
                context: .init(type: Value.self)
            )
            
            if !(base is Encodable), let base = base as? (any _UnsafeSerializationRepresentable) {
                try base._unsafeSerializationRepresentation.encode(to: wrappedEncoder)
            } else {
                if !(isBaseUnwrapped == true) {
                    let unwrappedBase = _unwrapPossiblyTypeErasedValue(base)
                    
                    if let unwrappedBase {
                        func _reifiedProxy<T>(for x: T) -> Encodable {
                            TopLevelProxyEncodable<T>(
                                base: x,
                                isBaseUnwrapped: true,
                                encoderConfiguration: encoderConfiguration
                            )
                        }
                        
                        let baseUnwrappedProxy = _openExistential(unwrappedBase, do: _reifiedProxy)
                        
                        try baseUnwrappedProxy.encode(to: encoder)
                    } else {
                        try cast(base, to: (any Encodable).self).encode(to: encoder)
                    }
                } else {
                    if
                        let base = base as? (any _UnsafelySerializedPropertyWrapperProtocol),
                        let unwrappedBase = base.wrappedValue as? Encodable,
                        try Self._encodeDiscriminator(for: __fixed_type(of: unwrappedBase), to: wrappedEncoder) != nil
                    {
                        try unwrappedBase.encode(to: wrappedEncoder)
                    } else if
                        let base = base as? _TypeSerializingAnyCodable,
                        let baseUnwrapped = try base.decode(),
                        try Self._encodeDiscriminator(for: __fixed_type(of: baseUnwrapped), to: wrappedEncoder) != nil
                    {
                        try baseUnwrapped.encode(to: wrappedEncoder)
                    } else {
                        let _base = try cast(base, to: (any Encodable).self)
                        
                        try Self._encodeDiscriminator(for: __fixed_type(of: _base), to: wrappedEncoder)
                        
                        try _base.encode(to: wrappedEncoder)
                    }
                }
            }
        }
        
        @discardableResult
        private static func _encodeDiscriminator(
            for type: Any.Type,
            to encoder: _ModularEncoder
        ) throws -> Any? {
            let pluginContext = _ModularCodingPluginContext()
            
            let concreteType = try cast(type, to: (any Encodable.Type).self)
            
            guard let typeDiscriminatorPlugin = encoder.configuration.plugins.first(ofType: (any _TypeDiscriminatorCodingPlugin).self) else {
                return nil
            }
            
            if let discriminator = try typeDiscriminatorPlugin.resolveDiscriminator(for: concreteType) {
                try typeDiscriminatorPlugin._opaque_encode(
                    discriminator,
                    to: encoder.disabling(typeDiscriminatorPlugin),
                    context: pluginContext
                )
                
                return discriminator
            } else {
                return nil
            }
        }
    }
}
