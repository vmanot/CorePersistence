//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Swallow

public protocol _ModularTopLevelDecoderOrEncoder {
    var plugins: [any _ModularCodingPlugin] { get set }
}

public protocol _ModularTopLevelCoder: _ModularTopLevelDecoderOrEncoder, TopLevelDecoder, TopLevelEncoder, Sendable where Input == Output {
    typealias EncodedRepresentation = Input
    
    func _eraseToAnyModularTopLevelCoder() -> _AnyModularTopLevelCoder<EncodedRepresentation>
}

extension _ModularTopLevelCoder {
    public func _opaque_eraseToAnyModularTopLevelCoder() -> any _ModularTopLevelCoder {
        _eraseToAnyModularTopLevelCoder()
    }
}

/// A wrapper coder that allows for polymorphic decoding.
public struct _AnyModularTopLevelCoder<EncodedRepresentation>: _ModularTopLevelCoder {
    private var decoder: _ModularTopLevelDecoder<EncodedRepresentation>
    private var encoder: _ModularTopLevelEncoder<EncodedRepresentation>
    
    public var plugins: [any _ModularCodingPlugin] {
        get {
            encoder.plugins
        } set {
            decoder.plugins = newValue
            encoder.plugins = newValue
        }
    }
    
    public init<Decoder: TopLevelDecoder, Encoder: TopLevelEncoder>(
        decoder: Decoder,
        encoder: Encoder
    ) where Decoder.Input == EncodedRepresentation, Encoder.Output == EncodedRepresentation {
        self.decoder = _ModularTopLevelDecoder(from: decoder)
        self.encoder = _ModularTopLevelEncoder(from: encoder)
    }
    
    public init<Coder: TopLevelDataCoder>(
        coder: Coder
    ) where EncodedRepresentation == Data {
        self.decoder = _ModularTopLevelDecoder(from: coder)
        self.encoder = _ModularTopLevelEncoder(from: coder)
    }
    
    public func decode<T>(
        _ type: T.Type,
        from input: EncodedRepresentation
    ) throws -> T {
        try decoder.decode(type, from: input)
    }
    
    public func encode<T>(_ value: T) throws -> EncodedRepresentation {
        try encoder.encode(value)
    }
    
    public func _eraseToAnyModularTopLevelCoder() -> _AnyModularTopLevelCoder<EncodedRepresentation> {
        self
    }
}

// MARK: - Conformances

extension _AnyModularTopLevelCoder: TopLevelDataCoder where EncodedRepresentation == Data {
    public var userInfo: [CodingUserInfoKey: Any] {
        get {
            fatalError(.unimplemented)
        } set {
            fatalError(.unimplemented)
        }
    }
}

// MARK: - Supplementary

extension TopLevelDecoder {
    public func _modular() -> _ModularTopLevelDecoder<Input> {
        _ModularTopLevelDecoder(from: self)
    }
}

extension TopLevelEncoder {
    public func _modular() -> _ModularTopLevelEncoder<Output> {
        _ModularTopLevelEncoder(from: self)
    }
}

extension TopLevelDataCoder {
    public func _modular() -> _AnyModularTopLevelCoder<Data> {
        if let result = self as? any _ModularTopLevelCoder {
            return result._opaque_eraseToAnyModularTopLevelCoder() as! _AnyModularTopLevelCoder<Data>
        } else {
            return _AnyModularTopLevelCoder(coder: self)
        }
    }
    
    public func __opaque_modular() -> any TopLevelDataCoder {
        self._modular()
    }
}

extension _AnySpecializedTopLevelDataCoder {
    public func _modular() -> Self {
        switch self {
            case .dataCodableType:
                return self
            case .topLevelDataCoder(let topLevelDataCoder, let type):
                return .topLevelDataCoder(topLevelDataCoder._modular(), forType: type)
            case .custom:
                return self
        }
    }
}
