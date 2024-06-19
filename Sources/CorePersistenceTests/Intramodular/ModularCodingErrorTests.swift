//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Diagnostics
import Swallow
import XCTest

fileprivate struct SomeStructure: Codable {
    var x: Int
    var y: Int
}

final class ModularCodingErrorTests: XCTestCase {
    func test() throws {
        let data: AnyCodable = ["x": 0]
        
        let regularDecoder = JSONDecoder()
        let modularDecoder = JSONDecoder()._modular()
        
        do {
            _ = try regularDecoder.decode(SomeStructure.self, from: data.toJSONData())
        } catch {
            _printEnclosedInASCIIBox(String(describing: error))
        }
        
        do {
            _ = try modularDecoder.decode(SomeStructure.self, from: data.toJSONData())
        } catch {
            _printEnclosedInASCIIBox(String(describing: error))
        }
    }
}
