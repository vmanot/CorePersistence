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
                
                🔎 Pretty error: \(Self.pretty(error: decodingError))
                
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
        
        /// Returns pretty description of given `DecodingError.Context`.
        private static func pretty(context: DecodingError.Context) -> String {
            let codingPath: [String] = context.codingPath.map { codingKey in
                if let intValue = codingKey.intValue {
                    return String(intValue)
                } else {
                    return codingKey.stringValue
                }
            }

            let result: String =
            """
            → In Context:
                → coding path: \(codingPath.joined(separator: " → "))
                → underlyingError: \(String(describing: context.underlyingError))
            """
            
            return result
        }
        
        private static func pretty(error: DecodingError) -> String {
            var description = "✋ description is unavailable"
            var context: DecodingError.Context?
            
            switch error {
                case .typeMismatch(let type, let moreContext):
                    description = "Type \(type) could not be decoded because it did not match the type of what was found in the encoded payload."
                    context = moreContext
                case .valueNotFound(let type, let moreContext):
                    description = "Non-optional value of type \(type) was expected, but a null value was found."
                    context = moreContext
                case .keyNotFound(let key, let moreContext):
                    description = "A keyed decoding container was asked for an entry for key \(key), but did not contain one."
                    context = moreContext
                case .dataCorrupted(let moreContext):
                    context = moreContext
                @unknown default:
                    break
            }
            
            return "\n→ \(description)" + (context.flatMap { pretty(context: $0) } ?? "")
        }
    }
}
