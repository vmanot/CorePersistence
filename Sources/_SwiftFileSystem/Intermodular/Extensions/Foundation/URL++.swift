//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift
import System
import UniformTypeIdentifiers

extension URL {
    public static func filePath(_ path: String) -> URL {
        URL(path: FilePath(path))
    }
    
    public static func filePath(_ path: @autoclosure () throws -> String?) throws -> URL {
        URL(path: FilePath(try path().unwrap()))
    }
}
