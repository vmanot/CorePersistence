//
// Copyright (c) Vatsal Manot
//

@_spi(Internal) import FoundationX
@_spi(Internal) import Swallow
import UniformTypeIdentifiers

public protocol _TopLevelFileDecoderEncoder {
    associatedtype DataType
    
    func __conversion<T>() throws -> _AnyTopLevelFileDecoderEncoder<T>
}
