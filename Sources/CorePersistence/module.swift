//
// Copyright (c) Vatsal Manot
//

@_exported import Diagnostics
@_exported import Expansions
@_exported import FoundationX
@_exported import Swallow

@attached(extension, conformances: HadeanIdentifiable, names: named(hadeanIdentifier))
public macro HadeanIdentifier(_ identifier: String) = #externalMacro(
    module: "CorePersistenceMacros",
    type: "HadeanIdentifierMacro"
)

public enum _module {
    private static var isInitialized: Bool = false
    
    public static func initialize() {
        guard !isInitialized else {
            return
        }
        
        defer {
            isInitialized = true
        }
        
        _UniversalTypeRegistry.register(UUID.self)
    }
}
