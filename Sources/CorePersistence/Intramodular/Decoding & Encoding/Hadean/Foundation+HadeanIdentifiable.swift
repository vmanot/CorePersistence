//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension Foundation.UUID: CorePersistence.HadeanIdentifiable {
    public static var hadeanIdentifier: HadeanIdentifier {
        "fusam-vomid-huzok-kokuz"
    }
}
