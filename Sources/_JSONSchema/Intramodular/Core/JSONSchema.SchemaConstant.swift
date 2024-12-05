//
// Copyright (c) Vatsal Manot
//

import Swallow

extension JSONSchema {
    public struct SchemaConstant: Codable, Hashable, Sendable {
        public enum Value: Hashable, Sendable {
            case integer(value: Int)
            case string(value: String)
        }
        
        public let value: Value
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch value {
                case .integer(let intValue):
                    try container.encode(intValue)
                case .string(let stringValue):
                    try container.encode(stringValue)
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let int = try? container.decode(Int.self) {
                value = .integer(value: int)
            } else if let string = try? container.decode(String.self) {
                value = .string(value: string)
            } else {
                let prettyKeyPath = container.codingPath.map({ $0.stringValue }).joined(separator: " → ")
                throw Exception.unimplemented(
                    "The value on key path: `\(prettyKeyPath)` is not supported by `JSONSchemaDefinition.ConstantValue`."
                )
            }
        }
    }
}
