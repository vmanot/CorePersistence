//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Foundation
import Swallow
import Testing

@Suite
struct ModularCodingRegressionTests {
    @Test
    func recursiveContainerShapesRoundTrip() throws {
        let value = RecursiveContainerFixture(
            keyed: .init(value: 1),
            unkeyed: [.init(value: 2), .init(value: 3)],
            singleValue: .init(value: .init(value: 4))
        )

        let encoded = try JSONEncoder()._modular().encode(value)
        let decoded = try JSONDecoder()._modular().decode(
            RecursiveContainerFixture.self,
            from: encoded
        )

        #expect(decoded == value)
    }

    @Test
    func keyedFoundationValuesPreserveDecoderStrategies() throws {
        let date = Date(timeIntervalSince1970: 1_725_000_000.125)
        let value = FoundationStrategyFixture(
            requiredDate: date,
            optionalDate: date,
            requiredURL: URL(string: "https://example.com/required")!,
            optionalURL: URL(string: "https://example.com/optional")!
        )
        let encoded = Data(
            #"""
            {
              "requiredDate": 1725000000125,
              "optionalDate": 1725000000125,
              "requiredURL": "https://example.com/required",
              "optionalURL": "https://example.com/optional"
            }
            """#.utf8
        )

        let baseDecoder = JSONDecoder()
        baseDecoder.dateDecodingStrategy = .millisecondsSince1970

        let decoded = try baseDecoder._modular().decode(
            FoundationStrategyFixture.self,
            from: encoded
        )

        #expect(decoded == value)
    }

    @Test
    func recoveryPluginPropagatesThroughManuallyNestedContainers() throws {
        var decoder = JSONDecoder()._modular()

        decoder.plugins = [
            _KeyNotFoundRecoveryPlugin()
        ]

        let decoded = try decoder.decode(
            ManuallyNestedRecoveryFixture.self,
            from: Data(#"{"keyed":{},"unkeyed":[{}]}"#.utf8)
        )

        #expect(decoded.keyedValues == [])
        #expect(decoded.unkeyedValues == [[]])
    }

    @Test
    func recoveryPluginPropagatesThroughSuperCoders() throws {
        var decoder = JSONDecoder()._modular()

        decoder.plugins = [
            _KeyNotFoundRecoveryPlugin()
        ]

        let recovered = try decoder.decode(
            SuperCodingChild.self,
            from: Data(#"{"name":"child","inherited":{}}"#.utf8)
        )

        #expect(recovered.name == "child")
        #expect(recovered.values == [])

        let original = SuperCodingChild(name: "round-trip", values: [1, 2, 3])
        let encoded = try JSONEncoder()._modular().encode(original)
        let decoded = try decoder.decode(SuperCodingChild.self, from: encoded)

        #expect(decoded.name == original.name)
        #expect(decoded.values == original.values)
    }

    @Test
    func codingKeyAliasesDecodeLegacyPayloadsWithoutChangingNewEncoding() throws {
        let decoded = try JSONDecoder()._modular().decode(
            RenamedFieldFixture.self,
            from: Data(#"{"legacyName":{"value":"legacy value"}}"#.utf8)
        )

        #expect(decoded.currentName == RenamedName(value: "legacy value"))

        let encoded = try JSONEncoder()._modular().encode(decoded)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        let currentName = try #require(object["currentName"] as? [String: String])

        #expect(currentName["value"] == "legacy value")
        #expect(object["legacyName"] == nil)
    }

    @Test
    func userInfoPropagatesThroughTopLevelProxies() throws {
        var encoder = JSONEncoder()._modular()
        encoder.userInfo[.modularCodingRegression] = "encoded"

        let encoded = try encoder.encode(UserInfoFixture(value: "payload"))

        var decoder = JSONDecoder()._modular()
        decoder.userInfo[.modularCodingRegression] = "decoded"

        let decoded = try decoder.decode(UserInfoFixture.self, from: encoded)

        #expect(decoded.value == "decoded:encoded:payload")
    }
}

private struct RecursiveContainerFixture: Codable, Equatable {
    var keyed: RecursiveLeaf
    var unkeyed: [RecursiveLeaf]
    var singleValue: SingleValueBox<RecursiveLeaf>
}

private struct RecursiveLeaf: Codable, Equatable {
    var value: Int
}

private struct SingleValueBox<Value: Codable & Equatable>: Codable, Equatable {
    var value: Value

    init(value: Value) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        value = try decoder.singleValueContainer().decode(Value.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(value)
    }
}

private struct FoundationStrategyFixture: Codable, Equatable {
    var requiredDate: Date
    var optionalDate: Date?
    var requiredURL: URL
    var optionalURL: URL?

    enum CodingKeys: String, CodingKey {
        case requiredDate
        case optionalDate
        case requiredURL
        case optionalURL
    }

    init(
        requiredDate: Date,
        optionalDate: Date?,
        requiredURL: URL,
        optionalURL: URL?
    ) {
        self.requiredDate = requiredDate
        self.optionalDate = optionalDate
        self.requiredURL = requiredURL
        self.optionalURL = optionalURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        requiredDate = try container.decode(Date.self, forKey: .requiredDate)
        optionalDate = try container.decode(Optional<Date>.self, forKey: .optionalDate)
        requiredURL = try container.decode(URL.self, forKey: .requiredURL)
        optionalURL = try container.decode(Optional<URL>.self, forKey: .optionalURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(requiredDate, forKey: .requiredDate)
        try container.encode(optionalDate, forKey: .optionalDate)
        try container.encode(requiredURL, forKey: .requiredURL)
        try container.encode(optionalURL, forKey: .optionalURL)
    }
}

private struct ManuallyNestedRecoveryFixture: Decodable {
    var keyedValues: [Int]
    var unkeyedValues: [[Int]]

    enum RootKeys: String, CodingKey {
        case keyed
        case unkeyed
    }

    enum NestedKeys: String, CodingKey {
        case values
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)
        let keyed = try root.nestedContainer(
            keyedBy: NestedKeys.self,
            forKey: .keyed
        )

        keyedValues = try keyed.decode([Int].self, forKey: .values)

        var unkeyed = try root.nestedUnkeyedContainer(forKey: .unkeyed)
        var decodedUnkeyedValues: [[Int]] = []

        while !unkeyed.isAtEnd {
            let element = try unkeyed.nestedContainer(keyedBy: NestedKeys.self)

            decodedUnkeyedValues.append(
                try element.decode([Int].self, forKey: .values)
            )
        }

        unkeyedValues = decodedUnkeyedValues
    }
}

private class SuperCodingBase: Codable {
    var values: [Int]

    enum CodingKeys: String, CodingKey {
        case values
    }

    init(values: [Int]) {
        self.values = values
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        values = try container.decode([Int].self, forKey: .values)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(values, forKey: .values)
    }
}

private final class SuperCodingChild: SuperCodingBase {
    var name: String

    enum CodingKeys: String, CodingKey {
        case name
        case inherited
    }

    init(name: String, values: [Int]) {
        self.name = name

        super.init(values: values)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)

        try super.init(from: container.superDecoder(forKey: .inherited))
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try super.encode(to: container.superEncoder(forKey: .inherited))
    }
}

private struct RenamedFieldFixture: _CodingRepresentationProvider, Equatable {
    var currentName: RenamedName

    static var codingRepresentation: some CodingRepresentation<Self> {
        CodingKeyAlias(source: "currentName", destination: "legacyName")
    }
}

private struct RenamedName: Codable, Equatable {
    var value: String
}

private struct UserInfoFixture: Codable, Equatable {
    var value: String

    init(value: String) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let prefix = try decoder.userInfo[CodingUserInfoKey.modularCodingRegression]
            .map({ try cast($0, to: String.self) })
            .unwrap()
        let encodedValue = try decoder.singleValueContainer().decode(String.self)

        value = "\(prefix):\(encodedValue)"
    }

    func encode(to encoder: Encoder) throws {
        let prefix = try encoder.userInfo[CodingUserInfoKey.modularCodingRegression]
            .map({ try cast($0, to: String.self) })
            .unwrap()
        var container = encoder.singleValueContainer()

        try container.encode("\(prefix):\(value)")
    }
}

private extension CodingUserInfoKey {
    static let modularCodingRegression = CodingUserInfoKey(
        rawValue: "ModularCodingRegressionTests"
    )!
}
