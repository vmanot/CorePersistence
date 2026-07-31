//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow
import Testing

fileprivate struct SomeStructure: Codable {
    var x: Int
    var y: Int
}

fileprivate struct StructureWithRecoverableArray: Codable, Equatable {
    var values: [Int]
}

fileprivate struct StructureWithWrongMissingKey: Decodable {
    var value: WrongMissingKey
}

fileprivate struct WrongMissingKey: Decodable, Initiable {
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

fileprivate struct StructureWithWrongMissingKeyPath: Decodable {
    var value: WrongMissingKeyPath
}

fileprivate struct WrongMissingKeyPath: Decodable, Initiable {
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

fileprivate enum DeliberateCodingKey: String, CodingKey {
    case other
    case unrelated
    case value
}

@Suite
struct ModularCodingErrorTests {
    @Test
    func testMissingKeyErrorsPreserveTheMissingKey() throws {
        let data: AnyCodable = ["x": 0]
        
        let regularDecoder = JSONDecoder()
        let modularDecoder = JSONDecoder()._modular()
        
        do {
            _ = try regularDecoder.decode(SomeStructure.self, from: data.toJSONData())

            Issue.record("Expected DecodingError.keyNotFound")
        } catch let error as DecodingError {
            guard case .keyNotFound(let key, _) = error else {
                Issue.record("Expected DecodingError.keyNotFound, received \(error)")

                return
            }

            #expect(key.stringValue == "y")
        } catch {
            Issue.record("Expected DecodingError.keyNotFound, received \(error)")
        }
        
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
    func testMissingKeyRecoveryDoesNotRecoverTypeMismatch() throws {
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
    func testMissingKeyRecoveryRequiresTheRequestedKeyAndContainerPath() throws {
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
