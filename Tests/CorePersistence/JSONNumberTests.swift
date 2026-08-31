import Testing
import _JSON

@Suite
struct JSONNumberTests {
    @Test
    func integralValuesAreRangeSafeAndHashConsistently() {
        let hugeIntegralDouble = JSONNumber(1e100)
        #expect(hugeIntegralDouble.integerValue == nil)

        let equivalentValues: Set<JSONNumber> = [
            JSONNumber(1),
            JSONNumber(1.0),
            JSONNumber(Int.max),
            JSONNumber(Double(Int.max)),
        ]
        #expect(JSONNumber(1) == JSONNumber(1.0))
        #expect(JSONNumber(Int.max) == JSONNumber(Double(Int.max)))
        #expect(equivalentValues.count == 2)
    }
}
