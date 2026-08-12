import Foundation
import Testing
import _JSON

@Suite
struct CanonicalJSONEncoderTests {
    private struct Fixture: Encodable {
        let z: Int
        let control: String
        let nonASCII: String
        let a: Bool
    }

    @Test
    func canonicalBytesAreIndependentOfDeclarationOrder() throws {
        let encoded: Data = try CanonicalJSONEncoder().encode(
            Fixture(z: 2, control: "\n", nonASCII: "€", a: true)
        )

        #expect(
            String(decoding: encoded, as: UTF8.self)
                == #"{"a":true,"control":"\n","nonASCII":"€","z":2}"#
        )
    }

    @Test
    func floatingPointValuesAreRejected() {
        #expect(throws: (any Error).self) {
            try CanonicalJSONEncoder().encode(["value": 1.5])
        }
    }
}
