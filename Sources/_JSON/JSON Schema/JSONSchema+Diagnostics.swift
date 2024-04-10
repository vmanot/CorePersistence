//
// Copyright (c) Vatsal Manot
//

import Foundation

extension JSONSchema {
    public struct Exception: Error, CustomStringConvertible {
        public let description: String
        
        init(
            _ reason: String,
            file: StaticString,
            line: UInt
        ) {
            // `file` includes slash-separated path, take only the last component:
            let fileName = "\(file)".split(separator: "/").last ?? "\(file)"
            let sourceReference = "🧭 Thrown in \(fileName):\(line)"
            
            self.description = "\(reason)\n\n\(sourceReference)"
        }
        
        public static func inconsistency(_ reason: String, file: StaticString = #fileID, line: UInt = #line) -> Exception {
            Exception("🐞 Inconsistency: \"\(reason)\".", file: file, line: line)
        }
        
        public static func illegal(_ operation: String, file: StaticString = #fileID, line: UInt = #line) -> Exception {
            Exception("⛔️ Illegal operation: \"\(operation)\".", file: file, line: line)
        }
        
        public static func unimplemented(_ operation: String, file: StaticString = #fileID, line: UInt = #line) -> Exception {
            Exception("🚧 Unimplemented: \"\(operation)\".", file: file, line: line)
        }
        
        static func moreContext(_ moreContext: String, for error: Error, file: StaticString = #fileID, line: UInt = #line) -> Exception {
            if let decodingError = error as? DecodingError {
                return Exception(
                """
                ⬇️
                🛑 \(moreContext)
                
                🔎 Pretty error: \(pretty(error: decodingError))
                
                ⚙️ Original error: \(decodingError)
                """,
                file: file,
                line: line
                )
            } else {
                return Exception(
                """
                ⬇️
                🛑 \(moreContext)
                
                ⚙️ Original error: \(error)
                """,
                file: file,
                line: line
                )
            }
        }
    }
}

extension Optional {
    func unwrapOrThrow(_ exception: JSONSchema.Exception) throws -> Wrapped {
        switch self {
            case .some(let unwrappedValue):
                return unwrappedValue
            case .none:
                throw exception
        }
    }
    
    func ifNotNil<T>(_ closure: (Wrapped) throws -> T) rethrows -> T? {
        if case .some(let unwrappedValue) = self {
            return try closure(unwrappedValue)
        } else {
            return nil
        }
    }
}

