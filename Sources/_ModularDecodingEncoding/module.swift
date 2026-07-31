//
// Copyright (c) Vatsal Manot
//

import Foundation

/// Values for which concrete coders may apply private, type-specific behavior.
///
/// Routing these values through a proxy calls their `Codable` conformances
/// directly and can silently bypass strategies owned by the underlying coder.
func _requiresDirectCodingWithUnderlyingCoder(
    _ type: Any.Type
) -> Bool {
    type == Date.self
        || type == Optional<Date>.self
        || type == Data.self
        || type == Optional<Data>.self
        || type == URL.self
        || type == Optional<URL>.self
}

public enum module {
    
}
