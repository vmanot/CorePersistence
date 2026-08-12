//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import FoundationX
import Testing

@Suite
struct _MetatypeCodingPluginTests {
    @Test
    func registeredMetatypeRoundTripsByPersistentIdentifier() throws {
        var coder = JSONCoder()._modular()

        coder.plugins = [_HadeanTypeCodingPlugin()]

        let testData = SomeMetatypeContainer(type: SomeType.self)
        let encodedTestData = try coder.encode(testData)
        let decodedTestData = try coder.decode(SomeMetatypeContainer.self, from: encodedTestData)

        #expect(
            ObjectIdentifier(decodedTestData.type)
                == ObjectIdentifier(SomeType.self)
        )
    }
}

extension _MetatypeCodingPluginTests {
    @RuntimeDiscoverable
    @HadeanIdentifier("libup-tatuz-huraf-supos")
    struct SomeType {

    }

    struct SomeMetatypeContainer: Codable {
        @_UnsafelySerialized
        var type: Any.Type
    }
}
