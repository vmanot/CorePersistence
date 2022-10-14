//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct _PersistentTypeRepresentedCodable: Codable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case typeRepresentation
        case data
    }
    
    private let typeRepresentation: _PersistentTypeRepresentation
    private let data: any Codable
    
    public init(_ data: any Codable) {
        self.typeRepresentation = .init(from: Swift.type(of: data))
        self.data = data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.typeRepresentation = try container.decode(_PersistentTypeRepresentation.self, forKey: .typeRepresentation)
        self.data = try cast(try container.decode(opaque: cast(self.typeRepresentation.resolveType(), to: Decodable.Type.self), forKey: .data), to: Codable.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(typeRepresentation, forKey: .typeRepresentation)
        try container.encode(data, forKey: .data)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeRepresentation)
        hasher.combine(AnyCodable(data))
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.typeRepresentation == rhs.typeRepresentation && AnyCodable(lhs.data) == AnyCodable(rhs.data)
    }
}
