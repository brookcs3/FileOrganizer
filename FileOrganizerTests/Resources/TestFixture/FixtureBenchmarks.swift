import Foundation
import XCTest // for XCTUnwrap
@testable import FileOrganizer   // <-- this line


private class TestHelperClass {}

enum TestHelper {
    /// URL to the bundled "TestFixture" folder inside FileOrganizerTests.xctest
    static func fixtureURL() throws -> URL {
        let bundle = Bundle(for: TestHelperClass.self) // test bundle
        let url = bundle.url(forResource: "TestFixture", withExtension: nil as String?)
        return try XCTUnwrap(url, "TestFixture not found in test bundle")
    }
}
