//
// Copyright (c) Vatsal Manot
//

import Swallow

extension JSONSchema {
    public subscript(
        path: Swallow.CodingPath
    ) -> JSONSchema? {
        get {
            guard !path.isEmpty else {
                return self
            }
            
            assert(self.type == .object)
            
            var path = Array(path)
            let firstKey: String = path.removeFirst().stringValue
            
            if let result = self.properties?[firstKey] {
                return result
            } else {
                return nil
            }
        } set {
            guard !path.isEmpty else {
                assert(newValue != nil)
                
                if let newValue {
                    self = newValue
                }
                
                return
            }
            
            var remainingPath = Array(path)
            let firstKey: String = remainingPath.removeFirst().stringValue
            
            if let newValue {
                let allKeys: Set<String> = Set(self.properties.map({ Array($0.keys) }) ?? [])
                
                if allKeys.contains(firstKey) {
                    self.properties?._forEach(mutating: {
                        if $0.key == firstKey {
                            $0.value[CodingPath(remainingPath)] = newValue
                        }
                    })
                } else {
                    assert(remainingPath.isEmpty)
                    
                    self.properties ??= [:]
                    
                    self.properties![firstKey] = newValue
                }
            } else {
                if path.isEmpty {
                    self.properties?[firstKey] = nil
                }
            }
        }
    }
}
