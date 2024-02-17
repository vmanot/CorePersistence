//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

public struct _UniversallyRegisteredType<Existential>: Hashable, Sendable {
    private let base: Metatype<Existential>
    
    public var value: Existential {
        base.value
    }
    
    public init(base: Metatype<Existential>) {
        assert(!base._isAnyOrNever(unwrapIfNeeded: true))
        
        self.base = base
    }
}

extension _UniversallyRegisteredType: CaseIterable {
    @MainActor(unsafe)
    public static var allCases: [_UniversallyRegisteredType<Existential>] {
        let types = _UniversalTypeRegistry.shared.compactMap {
            $0._unwrapBase() as? Existential
        }
        
        guard !types.isEmpty else {
            assertionFailure()
            
            return []
        }
        
        return types.map({ .init(base: .init($0)) })
    }
}
