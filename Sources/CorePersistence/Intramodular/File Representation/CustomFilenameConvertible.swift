//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow
import UniformTypeIdentifiers

public protocol CustomFilenameConvertible {
    var filenameProvider: URL.Filename { get }
}

// MARK: - Conformances

extension URL {
    public struct Filename: CustomFilenameConvertible {
        public var name: String
        
        public var filenameProvider: URL.Filename {
            self
        }
        
        public init(name: String) {
            self.name = name
        }
        
        public func filename(
            inDirectory url: URL
        ) -> String {
            name
        }
    }
}

extension UUID: CustomFilenameConvertible {
    public var filenameProvider: URL.Filename {
        URL.Filename(name: description)
    }
}

extension _TypeAssociatedID: CustomFilenameConvertible where RawValue: CustomFilenameConvertible {
    public var filenameProvider: URL.Filename {
        rawValue.filenameProvider
    }
}
