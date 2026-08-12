//
// Copyright (c) Vatsal Manot
//

import Swallow

extension JSONSchema {
    public indirect enum EnumValue: Codable, Hashable, Sendable {
        case null
        case boolean(Bool)
        case string(String)
        case integer(Int)
        case number(Double)
        case array([EnumValue])
        case object([String: EnumValue])

        public init(from decoder: Decoder) throws {
            let singleValueContainer = try decoder.singleValueContainer()
            if singleValueContainer.decodeNil() {
                self = .null
            } else if let boolean = try? singleValueContainer.decode(Bool.self) {
                self = .boolean(boolean)
            } else if let string = try? singleValueContainer.decode(String.self) {
                self = .string(string)
            } else if let integer = try? singleValueContainer.decode(Int.self) {
                self = .integer(integer)
            } else if let number = try? singleValueContainer.decode(Double.self) {
                self = .number(number)
            } else if let array = try? singleValueContainer.decode([EnumValue].self) {
                self = .array(array)
            } else if let object = try? singleValueContainer.decode([String: EnumValue].self) {
                self = .object(object)
            } else {
                throw DecodingError.dataCorruptedError(
                    in: singleValueContainer,
                    debugDescription: "Expected a JSON value in a schema enum"
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch self {
            case .null:
                try container.encodeNil()
            case .boolean(let value):
                try container.encode(value)
            case .string(let stringValue):
                try container.encode(stringValue)
            case .integer(let intValue):
                try container.encode(intValue)
            case .number(let value):
                try container.encode(value)
            case .array(let value):
                try container.encode(value)
            case .object(let value):
                try container.encode(value)
            }
        }
    }
}
