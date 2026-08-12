//
// Copyright (c) Vatsal Manot
//

import Swallow

extension JSONSchema {
    public struct SchemaConstant: Codable, Hashable, Sendable {
        public indirect enum Value: Codable, Hashable, Sendable {
            case null
            case boolean(value: Bool)
            case integer(value: Int)
            case number(value: Double)
            case string(value: String)
            case array(value: [Value])
            case object(value: [String: Value])

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()

                switch self {
                case .null:
                    try container.encodeNil()
                case .boolean(let value):
                    try container.encode(value)
                case .integer(let value):
                    try container.encode(value)
                case .number(let value):
                    try container.encode(value)
                case .string(let value):
                    try container.encode(value)
                case .array(let value):
                    try container.encode(value)
                case .object(let value):
                    try container.encode(value)
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()

                if container.decodeNil() {
                    self = .null
                } else if let value = try? container.decode(Bool.self) {
                    self = .boolean(value: value)
                } else if let value = try? container.decode(Int.self) {
                    self = .integer(value: value)
                } else if let value = try? container.decode(Double.self) {
                    self = .number(value: value)
                } else if let value = try? container.decode(String.self) {
                    self = .string(value: value)
                } else if let value = try? container.decode([Value].self) {
                    self = .array(value: value)
                } else if let value = try? container.decode([String: Value].self) {
                    self = .object(value: value)
                } else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Expected a JSON value for schema const"
                    )
                }
            }
        }

        public let value: Value

        public init(value: Value) {
            self.value = value
        }

        public func encode(to encoder: Encoder) throws {
            try value.encode(to: encoder)
        }

        public init(from decoder: Decoder) throws {
            value = try Value(from: decoder)
        }
    }
}
