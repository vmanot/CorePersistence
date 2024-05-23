//
// Copyright (c) Vatsal Manot
//

import Swallow

extension JSONSchema {
    public enum EnumValue: Codable, Hashable, Sendable {
        case string(String)
        case integer(Int)
        
        public init(from decoder: Decoder) throws {
            let singleValueContainer = try decoder.singleValueContainer()
            if let string = try? singleValueContainer.decode(String.self) {
                self = .string(string)
            } else if let integer = try? singleValueContainer.decode(Int.self) {
                self = .integer(integer)
            } else {
                throw Exception.unimplemented("Trying to decode `EnumValue` but its none of supported values.")
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
                case .string(let stringValue):
                    try container.encode(stringValue)
                case .integer(let intValue):
                    try container.encode(intValue)
            }
        }
    }
}
