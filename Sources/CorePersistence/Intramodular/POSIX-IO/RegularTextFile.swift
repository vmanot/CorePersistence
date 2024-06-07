//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

public class RegularTextFile<Encoding: StringEncodingType, AccessMode: FileAccessModeType>: RegularFile<String, AccessMode> {
    
}

extension RegularTextFile where AccessMode: FileAccessModeTypeForReading {
    public func data() throws -> String {
        return try data(
            using: String.DataDecodingStrategy(encoding: Encoding.encodingTypeValue)
        )
    }
}

extension RegularTextFile where AccessMode: FileAccessModeTypeForWriting {
    public func write(
        _ data: String
    ) throws {
        let writeStrategy = String.DataEncodingStrategy(
            encoding: Encoding.encodingTypeValue,
            allowLossyConversion: false
        )
        
        try write(data, using: writeStrategy)
    }
}

extension RegularTextFile where AccessMode: FileAccessModeTypeForUpdating {
    public var unsafelyAccessedData: String {
        get {
            return try! data()
        } set {
            try! write(newValue)
        }
    }
}
