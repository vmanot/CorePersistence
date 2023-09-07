//
// Copyright (c) Vatsal Manot
//

import CryptoKit

extension Digest {
    public var hexadecimalString: String {
        map({ String(format: "%02x", $0) }).joined()
    }
}
