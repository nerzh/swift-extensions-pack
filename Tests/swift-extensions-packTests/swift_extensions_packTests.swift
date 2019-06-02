import XCTest
@testable import swift_extensions_pack

final class swift_extensions_packTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_extensions_pack().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
