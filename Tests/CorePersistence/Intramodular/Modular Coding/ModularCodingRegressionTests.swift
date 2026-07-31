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
    func modularCoderWithoutPluginsMatchesUnderlyingCoder() throws {
        let date = Date(timeIntervalSince1970: 1_725_000_000.125)
        let bytes = Data([0x01, 0x02, 0x03])
        let value = FoundationStrategyFixture(
            requiredDate: date,
            optionalDate: date,
            requiredData: bytes,
            optionalData: bytes,
            requiredURL: URL(string: "https://example.com/required")!,
            optionalURL: URL(string: "https://example.com/optional")!
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.dataEncodingStrategy = RegressionDataStrategy.encoding

        let modularBaseEncoder = JSONEncoder()
        modularBaseEncoder.dateEncodingStrategy = .millisecondsSince1970
        modularBaseEncoder.dataEncodingStrategy = RegressionDataStrategy.encoding

        let baseEncoded = try encoder.encode(value)
        let modularEncoded = try modularBaseEncoder._modular().encode(value)
        let baseJSON = try JSONDecoder().decode(AnyCodable.self, from: baseEncoded)
        let modularJSON = try JSONDecoder().decode(AnyCodable.self, from: modularEncoded)

        #expect(modularJSON == baseJSON)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.dataDecodingStrategy = RegressionDataStrategy.decoding

        let modularBaseDecoder = JSONDecoder()
        modularBaseDecoder.dateDecodingStrategy = .millisecondsSince1970
        modularBaseDecoder.dataDecodingStrategy = RegressionDataStrategy.decoding

        #expect(
            try modularBaseDecoder._modular().decode(
                FoundationStrategyFixture.self,
                from: baseEncoded
            ) == decoder.decode(FoundationStrategyFixture.self, from: baseEncoded)
        )

        let malformed = Data(
            #"""
            {
              "requiredDate": "not milliseconds",
              "optionalDate": null,
              "requiredData": "modular-regression:AQID",
              "optionalData": null,
              "requiredURL": "https://example.com/required",
              "optionalURL": null
            }
            """#.utf8
        )
        let baseError = try #require(
            captureError {
                _ = try decoder.decode(FoundationStrategyFixture.self, from: malformed)
            }
        )
        let modularError = try #require(
            captureError {
                _ = try modularBaseDecoder._modular().decode(
                    FoundationStrategyFixture.self,
                    from: malformed
                )
            }
        )

        #expect(
            try #require(decodingFailureSnapshot(baseError))
                == #require(decodingFailureSnapshot(modularError))
        )
    }

    @Test
    func evolvedSingleValueRecursionFallbackRemainsAvailable() throws {
        let input = Data("42".utf8)
        let base = try JSONDecoder().decode(
            RequiresUnderlyingSingleValueDecoder.self,
            from: input
        )
        let modular = try JSONDecoder()._modular().decode(
            RequiresUnderlyingSingleValueDecoder.self,
            from: input
        )

        #expect(modular == base)
    }

    @Test
    func keyedFoundationValuesPreserveCoderStrategies() throws {
        let date = Date(timeIntervalSince1970: 1_725_000_000.125)
        let bytes = Data([0x01, 0x02, 0x03])
        let value = FoundationStrategyFixture(
            requiredDate: date,
            optionalDate: date,
            requiredData: bytes,
            optionalData: bytes,
            requiredURL: URL(string: "https://example.com/required")!,
            optionalURL: URL(string: "https://example.com/optional")!
        )

        let baseEncoder = JSONEncoder()
        baseEncoder.dateEncodingStrategy = .millisecondsSince1970
        baseEncoder.dataEncodingStrategy = RegressionDataStrategy.encoding

        let encoded = try baseEncoder._modular().encode(value)
        let rawValues = try JSONDecoder().decode(RawFoundationFixture.self, from: encoded)

        #expect(rawValues.requiredDate == date.timeIntervalSince1970 * 1_000)
        #expect(rawValues.optionalDate == date.timeIntervalSince1970 * 1_000)
        #expect(rawValues.requiredData == RegressionDataStrategy.encoded(bytes))
        #expect(rawValues.optionalData == RegressionDataStrategy.encoded(bytes))

        let baseDecoder = JSONDecoder()
        baseDecoder.dateDecodingStrategy = .millisecondsSince1970
        baseDecoder.dataDecodingStrategy = RegressionDataStrategy.decoding

        let decoded = try baseDecoder._modular().decode(
            FoundationStrategyFixture.self,
            from: encoded
        )

        #expect(decoded == value)
    }

    @Test
    func foundationStrategiesSurviveTopLevelUnkeyedAndSingleValueProxies() throws {
        let date = Date(timeIntervalSince1970: 1_725_000_000.125)
        let expectedMilliseconds = date.timeIntervalSince1970 * 1_000
        let dateEncoder = JSONEncoder()
        dateEncoder.dateEncodingStrategy = .millisecondsSince1970
        let dateDecoder = JSONDecoder()
        dateDecoder.dateDecodingStrategy = .millisecondsSince1970

        let encodedTopLevelDate = try dateEncoder._modular().encode(date)

        #expect(
            try JSONDecoder().decode(Double.self, from: encodedTopLevelDate)
                == expectedMilliseconds
        )
        #expect(
            try dateDecoder._modular().decode(Date.self, from: encodedTopLevelDate)
                == date
        )

        let dates: [Date?] = [date, nil]
        let encodedDates = try dateEncoder._modular().encode(dates)

        #expect(
            try JSONDecoder().decode([Double?].self, from: encodedDates)
                == [expectedMilliseconds, nil]
        )
        #expect(
            try dateDecoder._modular().decode([Date?].self, from: encodedDates)
                == dates
        )

        let singleValueDate = SingleValueBox(value: date)
        let encodedSingleValueDate = try dateEncoder._modular().encode(singleValueDate)

        #expect(
            try JSONDecoder().decode(Double.self, from: encodedSingleValueDate)
                == expectedMilliseconds
        )
        #expect(
            try dateDecoder._modular().decode(
                SingleValueBox<Date>.self,
                from: encodedSingleValueDate
            ) == singleValueDate
        )

        let bytes = Data([0x01, 0x02, 0x03])
        let dataEncoder = JSONEncoder()
        dataEncoder.dataEncodingStrategy = RegressionDataStrategy.encoding
        let dataDecoder = JSONDecoder()
        dataDecoder.dataDecodingStrategy = RegressionDataStrategy.decoding
        let encodedData = try dataEncoder._modular().encode(bytes)

        #expect(
            try JSONDecoder().decode(String.self, from: encodedData)
                == RegressionDataStrategy.encoded(bytes)
        )
        #expect(
            try dataDecoder._modular().decode(Data.self, from: encodedData)
                == bytes
        )

        let dataValues: [Data?] = [bytes, nil]
        let encodedDataValues = try dataEncoder._modular().encode(dataValues)

        #expect(
            try JSONDecoder().decode([String?].self, from: encodedDataValues)
                == [RegressionDataStrategy.encoded(bytes), nil]
        )
        #expect(
            try dataDecoder._modular().decode([Data?].self, from: encodedDataValues)
                == dataValues
        )

        let singleValueData = SingleValueBox(value: bytes)
        let encodedSingleValueData = try dataEncoder._modular().encode(singleValueData)

        #expect(
            try JSONDecoder().decode(String.self, from: encodedSingleValueData)
                == RegressionDataStrategy.encoded(bytes)
        )
        #expect(
            try dataDecoder._modular().decode(
                SingleValueBox<Data>.self,
                from: encodedSingleValueData
            ) == singleValueData
        )
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
            from: Data(
                #"{"legacyName":"legacy value","legacyOptionalName":"optional legacy value"}"#.utf8
            )
        )

        #expect(decoded.currentName == "legacy value")
        #expect(decoded.optionalName == "optional legacy value")

        let encoded = try JSONEncoder()._modular().encode(decoded)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )

        #expect(object["currentName"] as? String == "legacy value")
        #expect(object["optionalName"] as? String == "optional legacy value")
        #expect(object["legacyName"] == nil)
        #expect(object["legacyOptionalName"] == nil)

        let canonicalWins = try JSONDecoder()._modular().decode(
            RenamedFieldFixture.self,
            from: Data(
                #"{"currentName":"canonical","legacyName":"legacy","optionalName":null,"legacyOptionalName":"ignored"}"#.utf8
            )
        )

        #expect(canonicalWins.currentName == "canonical")
        #expect(canonicalWins.optionalName == nil)

        let nested = try JSONDecoder()._modular().decode(
            RenamedNestedFixture.self,
            from: Data(#"{"legacyName":{"value":"nested legacy value"}}"#.utf8)
        )

        #expect(nested.currentName == RenamedName(value: "nested legacy value"))

        let encodedNested = try JSONEncoder()._modular().encode(nested)
        let nestedObject = try #require(
            JSONSerialization.jsonObject(with: encodedNested) as? [String: Any]
        )

        #expect(nestedObject["currentName"] != nil)
        #expect(nestedObject["legacyName"] == nil)
    }

    @Test
    func malformedAliasIsNotDiscardedOrReplacedByRecovery() throws {
        var decoder = JSONDecoder()._modular()

        decoder.plugins = [
            _KeyNotFoundRecoveryPlugin()
        ]

        let valid = try decoder.decode(
            RenamedIntegerFixture.self,
            from: Data(#"{"legacyCount":42}"#.utf8)
        )

        #expect(valid.currentCount == 42)

        do {
            _ = try decoder.decode(
                RenamedIntegerFixture.self,
                from: Data(
                    #"{"currentCount":"malformed canonical","legacyCount":42}"#.utf8
                )
            )

            Issue.record("A malformed canonical value must not fall back to an alias")
        } catch {
            guard
                let modularError = _ModularDecodingError(error),
                case .typeMismatch = modularError
            else {
                Issue.record("Expected the canonical typeMismatch, received \(error)")

                return
            }
        }

        do {
            _ = try decoder.decode(
                RenamedIntegerFixture.self,
                from: Data(#"{"legacyCount":"not an integer"}"#.utf8)
            )

            Issue.record("A present malformed alias must not be replaced with a default")
        } catch {
            guard
                let modularError = _ModularDecodingError(error),
                case .typeMismatch = modularError
            else {
                Issue.record("Expected the alias typeMismatch to be preserved, received \(error)")

                return
            }
        }

        do {
            _ = try decoder.decode(
                RenamedFieldFixture.self,
                from: Data(
                    #"{"currentName":"canonical","legacyOptionalName":42}"#.utf8
                )
            )

            Issue.record("A malformed optional alias must not be discarded as nil")
        } catch {
            guard
                let modularError = _ModularDecodingError(error),
                case .typeMismatch = modularError
            else {
                Issue.record("Expected the optional alias typeMismatch, received \(error)")

                return
            }
        }
    }

    @Test
    func aliasRecoveryStillTriesAnotherPresentAliasAfterOneFails() throws {
        let decoded = try JSONDecoder()._modular().decode(
            MultipleAliasIntegerFixture.self,
            from: Data(
                #"{"legacyCount":"not an integer","olderCount":42}"#.utf8
            )
        )

        #expect(decoded.currentCount == 42)
    }

    @Test
    func primitiveMissingKeyRecoveryUsesTheSameValidatedPath() throws {
        var decoder = JSONDecoder()._modular()

        decoder.plugins = [
            _KeyNotFoundRecoveryPlugin()
        ]

        let decoded = try decoder.decode(
            RecoverablePrimitiveFixture.self,
            from: Data(#"{}"#.utf8)
        )

        #expect(decoded.value == "")
    }

    @Test
    func hiddenPrimitiveKeysRespectRequiredAndOptionalDecoding() throws {
        let optional = try JSONDecoder()._modular().decode(
            HiddenOptionalPrimitiveFixture.self,
            from: Data(#"{"visible":"visible","secret":"secret"}"#.utf8)
        )

        #expect(optional.visible == "visible")
        #expect(optional.secret == nil)

        do {
            _ = try JSONDecoder()._modular().decode(
                HiddenRequiredPrimitiveFixture.self,
                from: Data(#"{"secret":"secret"}"#.utf8)
            )

            Issue.record("A hidden required key must be forbidden")
        } catch {
            guard
                let modularError = _ModularDecodingError(error),
                case .keyForbidden(let key, _) = modularError
            else {
                Issue.record("Expected keyForbidden, received \(error)")

                return
            }

            #expect(key.stringValue == "secret")
        }
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

    private struct DecodingFailureSnapshot: Equatable {
        enum Kind: Equatable {
            case dataCorrupted
            case keyNotFound
            case typeMismatch
            case valueNotFound
        }

        var kind: Kind
        var path: [String]
    }

    private enum RegressionDataStrategy {
        static let prefix = "modular-regression:"

        static func encoded(
            _ data: Data
        ) -> String {
            "\(prefix)\(data.base64EncodedString())"
        }

        static var encoding: JSONEncoder.DataEncodingStrategy {
            .custom { data, encoder in
                var container = encoder.singleValueContainer()

                try container.encode(encoded(data))
            }
        }

        static var decoding: JSONDecoder.DataDecodingStrategy {
            .custom { decoder in
                let encoded = try decoder.singleValueContainer().decode(String.self)

                guard
                    encoded.hasPrefix(prefix),
                    let data = Data(base64Encoded: String(encoded.dropFirst(prefix.count)))
                else {
                    throw DecodingError.dataCorrupted(
                        .init(
                            codingPath: decoder.codingPath,
                            debugDescription: "Expected regression-prefixed data."
                        )
                    )
                }

                return data
            }
        }
    }

    private func captureError(
        _ operation: () throws -> Void
    ) -> Error? {
        do {
            try operation()

            return nil
        } catch {
            return error
        }
    }

    private func decodingFailureSnapshot(
        _ error: Error
    ) -> DecodingFailureSnapshot? {
        if let error = error as? DecodingError {
            switch error {
                case .dataCorrupted(let context):
                    return .init(
                        kind: .dataCorrupted,
                        path: context.codingPath.map(\.stringValue)
                    )
                case .keyNotFound(_, let context):
                    return .init(
                        kind: .keyNotFound,
                        path: context.codingPath.map(\.stringValue)
                    )
                case .typeMismatch(_, let context):
                    return .init(
                        kind: .typeMismatch,
                        path: context.codingPath.map(\.stringValue)
                    )
                case .valueNotFound(_, let context):
                    return .init(
                        kind: .valueNotFound,
                        path: context.codingPath.map(\.stringValue)
                    )
                @unknown default:
                    return nil
            }
        }

        guard let error = _ModularDecodingError(error) else {
            return nil
        }

        let path = error.context?.codingPath.compactMap({
            try? $0.key.unwrap().stringValue
        }) ?? []

        switch error {
            case .dataCorrupted:
                return .init(kind: .dataCorrupted, path: path)
            case .keyNotFound:
                return .init(kind: .keyNotFound, path: path)
            case .typeMismatch:
                return .init(kind: .typeMismatch, path: path)
            case .valueNotFound:
                return .init(kind: .valueNotFound, path: path)
            default:
                return nil
        }
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
    var requiredData: Data
    var optionalData: Data?
    var requiredURL: URL
    var optionalURL: URL?

    enum CodingKeys: String, CodingKey {
        case requiredDate
        case optionalDate
        case requiredData
        case optionalData
        case requiredURL
        case optionalURL
    }

    init(
        requiredDate: Date,
        optionalDate: Date?,
        requiredData: Data,
        optionalData: Data?,
        requiredURL: URL,
        optionalURL: URL?
    ) {
        self.requiredDate = requiredDate
        self.optionalDate = optionalDate
        self.requiredData = requiredData
        self.optionalData = optionalData
        self.requiredURL = requiredURL
        self.optionalURL = optionalURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        requiredDate = try container.decode(Date.self, forKey: .requiredDate)
        optionalDate = try container.decode(Optional<Date>.self, forKey: .optionalDate)
        requiredData = try container.decode(Data.self, forKey: .requiredData)
        optionalData = try container.decode(Optional<Data>.self, forKey: .optionalData)
        requiredURL = try container.decode(URL.self, forKey: .requiredURL)
        optionalURL = try container.decode(Optional<URL>.self, forKey: .optionalURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(requiredDate, forKey: .requiredDate)
        try container.encode(optionalDate, forKey: .optionalDate)
        try container.encode(requiredData, forKey: .requiredData)
        try container.encode(optionalData, forKey: .optionalData)
        try container.encode(requiredURL, forKey: .requiredURL)
        try container.encode(optionalURL, forKey: .optionalURL)
    }
}

private struct RawFoundationFixture: Decodable {
    var requiredDate: Double
    var optionalDate: Double?
    var requiredData: String
    var optionalData: String?
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
    var currentName: String
    var optionalName: String?

    @CodingRepresentationBuilder<Self>
    static var codingRepresentation: some CodingRepresentation<Self> {
        CodingKeyAlias(source: "currentName", destination: "legacyName")
        CodingKeyAlias(source: "optionalName", destination: "legacyOptionalName")
    }
}

private struct RenamedIntegerFixture: _CodingRepresentationProvider {
    var currentCount: Int

    static var codingRepresentation: some CodingRepresentation<Self> {
        CodingKeyAlias(source: "currentCount", destination: "legacyCount")
    }
}

private struct RenamedNestedFixture: _CodingRepresentationProvider, Equatable {
    var currentName: RenamedName

    static var codingRepresentation: some CodingRepresentation<Self> {
        CodingKeyAlias(source: "currentName", destination: "legacyName")
    }
}

private struct RenamedName: Codable, Equatable {
    var value: String
}

private struct MultipleAliasIntegerFixture: _CodingRepresentationProvider {
    var currentCount: Int

    @CodingRepresentationBuilder<Self>
    static var codingRepresentation: some CodingRepresentation<Self> {
        CodingKeyAlias(source: "currentCount", destination: "legacyCount")
        CodingKeyAlias(source: "currentCount", destination: "olderCount")
    }
}

private struct RecoverablePrimitiveFixture: Decodable {
    var value: String
}

private struct RequiresUnderlyingSingleValueDecoder: Decodable, Equatable {
    var value: Int

    init(from decoder: Decoder) throws {
        if decoder is _ModularDecoder {
            throw RequiresUnderlyingSingleValueDecoderError.requiresUnderlyingDecoder
        }

        value = try decoder.singleValueContainer().decode(Int.self)
    }
}

private enum RequiresUnderlyingSingleValueDecoderError: Error {
    case requiresUnderlyingDecoder
}

private struct HiddenOptionalPrimitiveFixture: Decodable {
    var visible: String
    var secret: String?

    enum CodingKeys: String, CodingKey {
        case visible
        case secret
    }

    init(from decoder: Decoder) throws {
        let decoder = decoder._hidingCodingKey(CodingKeys.secret)
        let container = try decoder.container(keyedBy: CodingKeys.self)

        visible = try container.decode(String.self, forKey: .visible)
        secret = try container.decodeIfPresent(String.self, forKey: .secret)
    }
}

private struct HiddenRequiredPrimitiveFixture: Decodable {
    var secret: String

    enum CodingKeys: String, CodingKey {
        case secret
    }

    init(from decoder: Decoder) throws {
        let decoder = decoder._hidingCodingKey(CodingKeys.secret)
        let container = try decoder.container(keyedBy: CodingKeys.self)

        secret = try container.decode(String.self, forKey: .secret)
    }
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
