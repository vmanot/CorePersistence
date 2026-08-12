//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow
import Testing

private struct SomeStructure: Codable {
    var x: Int
    var y: Int
}

private struct StructureWithRecoverableArray: Codable, Equatable {
    var values: [Int]
}

private struct StructureWithWrongMissingKey: Decodable {
    var value: WrongMissingKey
}

private struct WrongMissingKey: Decodable, Initiable {
    init() {

    }

    init(from decoder: Decoder) throws {
        throw DecodingError.keyNotFound(
            DeliberateCodingKey.other,
            .init(
                codingPath: Array(decoder.codingPath.dropLast()),
                debugDescription: "Deliberately report a different missing key."
            )
        )
    }
}

private struct StructureWithWrongMissingKeyPath: Decodable {
    var value: WrongMissingKeyPath
}

private struct WrongMissingKeyPath: Decodable, Initiable {
    init() {

    }

    init(from decoder: Decoder) throws {
        throw DecodingError.keyNotFound(
            DeliberateCodingKey.value,
            .init(
                codingPath: [DeliberateCodingKey.unrelated],
                debugDescription: "Deliberately report the missing key at another path."
            )
        )
    }
}

private enum DeliberateCodingKey: String, CodingKey {
    case other
    case unrelated
    case value
}

@Suite
struct ModularCodingErrorTests {
    @Test
    func missingKeyErrorsPreserveTheMissingKey() throws {
        let data: AnyCodable = ["x": 0]
        let modularDecoder = JSONDecoder()._modular()

        do {
            _ = try modularDecoder.decode(SomeStructure.self, from: data.toJSONData())

            Issue.record("Expected _ModularDecodingError.keyNotFound")
        } catch {
            guard
                let modularError = _ModularDecodingError(error),
                case .keyNotFound(let key, _, _) = modularError
            else {
                Issue.record("Expected _ModularDecodingError.keyNotFound, received \(error)")

                return
            }

            #expect(key.stringValue == "y")
        }
    }

    @Test
    func missingKeyRecoveryDoesNotRecoverTypeMismatch() throws {
        var decoder = JSONDecoder()._modular()

        decoder.plugins = [
            _KeyNotFoundRecoveryPlugin()
        ]

        let missingKeyData: AnyCodable = [:]
        let recovered = try decoder.decode(
            StructureWithRecoverableArray.self,
            from: missingKeyData.toJSONData()
        )

        #expect(recovered == StructureWithRecoverableArray(values: []))

        let malformedValueData: AnyCodable = ["values": "not an array"]

        do {
            _ = try decoder.decode(
                StructureWithRecoverableArray.self,
                from: malformedValueData.toJSONData()
            )

            Issue.record("Expected typeMismatch")
        } catch {
            guard
                let modularError = _ModularDecodingError(error),
                case .typeMismatch = modularError
            else {
                Issue.record("Expected typeMismatch to be preserved, received \(error)")

                return
            }
        }
    }

    @Test
    func missingKeyRecoveryRequiresTheRequestedKeyAndContainerPath() throws {
        var decoder = JSONDecoder()._modular()

        decoder.plugins = [
            _KeyNotFoundRecoveryPlugin()
        ]

        do {
            _ = try decoder.decode(
                StructureWithWrongMissingKey.self,
                from: Data(#"{"value":{}}"#.utf8)
            )

            Issue.record("A different missing key must not recover the requested value")
        } catch {
            guard
                let modularError = _ModularDecodingError(error),
                case .keyNotFound(let key, _, _) = modularError
            else {
                Issue.record("Expected keyNotFound, received \(error)")

                return
            }

            #expect(key.stringValue == "other")
        }

        do {
            _ = try decoder.decode(
                StructureWithWrongMissingKeyPath.self,
                from: Data(#"{"value":{}}"#.utf8)
            )

            Issue.record("A missing key from another path must not recover the requested value")
        } catch {
            guard
                let modularError = _ModularDecodingError(error),
                case .keyNotFound(let key, _, _) = modularError
            else {
                Issue.record("Expected keyNotFound, received \(error)")

                return
            }

            #expect(key.stringValue == "value")
        }
    }
}
