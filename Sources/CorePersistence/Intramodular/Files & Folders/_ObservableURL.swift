//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public final class _ObservableURL: ObservableObject {
    public var url: BookmarkedURL
    
    public init(from url: URL) throws {
        self.url = try BookmarkedURL(url: url).unwrap()
    }
    
    public func resolve() -> URL {
        url.url
    }
}
