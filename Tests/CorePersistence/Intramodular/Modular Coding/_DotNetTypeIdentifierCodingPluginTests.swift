//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Testing

@testable import CorePersistence

@Suite
struct DotNetTypeIdentifierCodingPluginTests {
    @Test
    func heterogeneousExistentialsRoundTripWithNestedChildren() throws {
        var coder = JSONCoder(outputFormatting: [.prettyPrinted, .sortedKeys])._modular()

        coder.plugins = [
            _DotNetTypeIdentifierCodingPlugin(
                idResolver: TestTypes.TypeToIdentifierResolver(),
                typeResolver: TestTypes.IdentifierToTypeResolver()
            )
        ]

        let data: [Any] = [
            TestTypes.Foo(x: 69, y: nil),
            TestTypes.Bar(x: 6.9, y: 9.6),
            TestTypes.Baz(
                children: [
                    TestTypes.Foo(x: 42),
                    TestTypes.Bar(x: 4.2),
                ]
            ),
        ]

        let encodedData = try coder.encode(data)

        let decoded = try coder.decode([Any].self, from: encodedData)
        try #require(decoded.count == 3)

        let decodedFoo = try #require(decoded[0] as? TestTypes.Foo)
        let decodedBar = try #require(decoded[1] as? TestTypes.Bar)
        let decodedBaz = try #require(decoded[2] as? TestTypes.Baz)

        #expect(decodedFoo == TestTypes.Foo(x: 69, y: nil))
        #expect(decodedBar == TestTypes.Bar(x: 6.9, y: 9.6))

        try #require(decodedBaz.children.count == 2)

        let decodedChildFoo = try #require(decodedBaz.children[0] as? TestTypes.Foo)
        let decodedChildBar = try #require(decodedBaz.children[1] as? TestTypes.Bar)

        #expect(decodedChildFoo == TestTypes.Foo(x: 42, y: nil))
        #expect(decodedChildBar == TestTypes.Bar(x: 4.2, y: nil))
    }
}

struct TestTypes {
    enum TypeIdentifier: String, Codable, Hashable, PersistentIdentifier {
        case foo
        case bar
        case baz

        public var body: some IdentityRepresentation {
            _StringIdentityRepresentation(rawValue)
        }
    }

    struct Foo: TestType {
        var x: Int
        var y: Int?
    }

    struct Bar: TestType {
        var x: Float
        var y: Float?
    }

    struct Baz: TestType {
        var x: Int {
            0
        }

        @_UnsafelySerialized
        var children: [any TestType]
    }
}

protocol TestType: Codable, Hashable {
    associatedtype X: Number

    var x: X { get }
}

extension TestTypes {
    struct IdentifierToTypeResolver: _PersistentIdentifierToSwiftTypeResolver {
        typealias Input = TypeIdentifier
        typealias Output = _StaticSwift.ExistentialTypeExpression<any TestType, any TestType.Type>

        fileprivate init() {

        }

        public func resolve(
            from input: Input
        ) throws -> Output? {
            switch input {
            case .foo:
                return .existential(Foo.self)
            case .bar:
                return .existential(Bar.self)
            case .baz:
                return .existential(Baz.self)
            }
        }
    }

    struct TypeToIdentifierResolver: _StaticSwiftTypeToPersistentIdentifierResolver {
        typealias Input = _StaticSwift.ExistentialTypeExpression<any TestType, any TestType.Type>
        typealias Output = TypeIdentifier

        fileprivate init() {

        }

        public func resolve(
            from input: Input
        ) throws -> Output? {
            switch input.value {
            case Foo.self:
                return .foo
            case Bar.self:
                return .bar
            case Baz.self:
                return .baz
            default:
                throw _AssertionFailure()
            }
        }
    }
}
