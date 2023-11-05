//
// Copyright (c) Vatsal Manot
//

@testable import CorePersistence

import Diagnostics
import FoundationX
import XCTest

final class TypeDiscriminatedCodingTests: XCTestCase {
    func testShit() throws {
        let coder = _ModularTopLevelCoder(coder: JSONCoder(outputFormatting: [.prettyPrinted, .sortedKeys]))
        
        let data = Baz(
            child1: Foo(x: 42),
            child2: Bar(x: 4.2)
        )
        
        let encodedData = try coder.encode(data)
        
        print(try String(data: encodedData, using: .init(encoding: .utf8)))
        XCTAssertNoThrow(try JSONDecoder().decode(AnyCodable.self, from: encodedData))
        
        let decoded = try coder.decode(Baz.self, from: encodedData)
        
        assert(data == decoded)
    }
}

private enum TestTypeDiscriminator: String, CaseIterable, Codable, Swallow.TypeDiscriminator {
    public typealias _DiscriminatedSwiftType = _ExistentialSwiftType<any TestType, any TestType.Type>
    
    case foo
    case bar
    case baz
    
    func resolveType() throws -> any TestType.Type {
        switch self {
            case .foo:
                return Foo.self
            case .bar:
                return Bar.self
            case .baz:
                return Baz.self
        }
    }
}

fileprivate protocol TestType: Codable, Hashable, TypeDiscriminable<TestTypeDiscriminator> {
    associatedtype X: Number
    
    var x: X { get }
}

private struct Foo: TestType {
    var x: Int
    var y: Int?
    
    var typeDiscriminator: TestTypeDiscriminator {
        .foo
    }
}

private struct Bar: TestType {
    var x: Float
    var y: Float?
    
    var typeDiscriminator: TestTypeDiscriminator {
        .bar
    }
}

private struct Baz: TestType {
    var x: Int {
        0
    }
    
    @TypeDiscriminated<TestTypeDiscriminator>
    var child1: any TestType
    
    @TypeDiscriminated<TestTypeDiscriminator>
    var child2: any TestType
    
    var typeDiscriminator: TestTypeDiscriminator {
        .baz
    }
}
