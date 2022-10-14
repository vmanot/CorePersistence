//
// Copyright (c) Vatsal Manot
//

import Swallow

///
/// An identifier in the reverse domain name notation form.
/// See more here - https://en.wikipedia.org/wiki/Reverse_domain_name_notation.
///
public struct ReverseDomainIdentifier: Codable, Hashable, Identifier {
    private let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(from decoder: Decoder) throws {
        try self.init(rawValue: String(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

// MARK: - Conformances -

extension ReverseDomainIdentifier: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value) // TODO: Add validation
    }
}

extension ReverseDomainIdentifier: IdentityRepresentation {
    public var body: some IdentityRepresentation {
        _StringIdentityRepresentation(rawValue)
    }
}
