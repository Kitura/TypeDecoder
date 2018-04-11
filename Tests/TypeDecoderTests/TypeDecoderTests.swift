import XCTest
@testable import TypeDecoder

class TypeDecoderTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TypeDecoder().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
