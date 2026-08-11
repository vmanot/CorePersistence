import XCTest
import _JSON

final class CanonicalJSONEncoderTests: XCTestCase {
    private struct Fixture: Encodable {
        let z: Int
        let control: String
        let nonASCII: String
        let a: Bool
    }

    func testCanonicalBytesAreIndependentOfDeclarationOrder() throws {
        let encoded: Data = try CanonicalJSONEncoder().encode(
            Fixture(z: 2, control: "\n", nonASCII: "€", a: true)
        )

        XCTAssertEqual(
            String(decoding: encoded, as: UTF8.self),
            #"{"a":true,"control":"\n","nonASCII":"€","z":2}"#
        )
    }

    func testFloatingPointSchemaIsRejected() throws {
        XCTAssertThrowsError(try CanonicalJSONEncoder().encode(["value": 1.5]))
    }
}
