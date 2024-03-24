//
// Copyright (c) Vatsal Manot
//

import Swift

@attached(extension, conformances: HadeanIdentifiable, names: named(hadeanIdentifier))
public macro HadeanIdentifier(_ identifier: String) = #externalMacro(
    module: "CorePersistenceMacros",
    type: "HadeanIdentifierMacro"
)
