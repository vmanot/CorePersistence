//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct _TypePersistingAnyCodable: Codable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    private let type: PersistableTypeIdentity
    private let value: any Codable
    
    public init(_ value: any Codable) {
        self.type = .init(from: Swift.type(of: value))
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.type = try container.decode(PersistableTypeIdentity.self, forKey: .type)
        self.value = try cast(try container.decode(opaque: cast(self.type.resolveType(), to: Decodable.Type.self), forKey: .value), to: Codable.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(value, forKey: .type)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(AnyCodable(value))
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && AnyCodable(lhs.value) == AnyCodable(rhs.value)
    }
}
