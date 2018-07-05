import Foundation
import XCTest
@testable import TypeDecoder

class OrderedDictionaryTests: XCTestCase {

    static var allTests = [
        ("testIterator", testIterator),
        ("testElementRemoval", testElementRemoval),
        ("testElementReplacement", testElementReplacement),
        ("testGetWithIntIndex", testGetWithIntIndex),
        ("testDescription", testDescription),
    ]

    func testIterator() {
        // Test that elements are found in the correct sequence.
        let keys = ["one", "two", "three", "four"]
        let values = ["1", "2", "3", "4"]
        var dict = OrderedDictionary<String, String>()
        var count = 0
        dict["one"] = "1"
        dict["two"] = "2"
        dict["three"] = "3"
        dict["four"] = "4"

        for (k, v) in dict {
            if keys[count] != k {
                XCTFail("key: \(keys[count]) not found or in wrong position")
                if values[count] != String(describing: v) {
                    XCTFail("value: \(values[count]) not found or in wrong position")
                }
            }
            count += 1
        }
    }

    func testElementRemoval() {
        // Test that setting an element to nil remove it
        var dict = OrderedDictionary<String, String>()
        dict["one"] = "1"
        dict["two"] = "2"
        dict["three"] = "3"
        dict["four"] = "4"
        dict["three"] = nil

        XCTAssertTrue(dict.count == 3, "wrong number of elements in dict, found \(dict.count), should have found 3") 
        XCTAssertTrue(dict["three"] == nil, "failed to remove an element from dict")
    }

    func testElementReplacement() {
        // Test that an element can be replaced.
        var dict = OrderedDictionary<String, String>()
        dict["one"] = "1"
        dict["two"] = "2"
        dict["two"] = "2+2"

        XCTAssertTrue(dict["two"] == "2+2", "failed to replace an element in dict")
    }

    func testGetWithIntIndex() {
        // Test that an element can be replaced.
        var dict = OrderedDictionary<String, String>()
        dict["one"] = "1"
        dict["two"] = "2"
        dict["three"] = "2+1"

        XCTAssertTrue(dict[0] == "1", "failed to get the correct element at index 0")
        XCTAssertTrue(dict[1] == "2", "failed to get the correct element at index 1")
        XCTAssertTrue(dict[2] == "2+1", "failed to get the correct element at index 2")
        XCTAssertTrue(dict[3] == nil, "failed to get nil element at out of range index")
    }

    func testDescription() {
        // Test that the description method returns a meaningful string.
        var dict = OrderedDictionary<String, String>()
        let testDesc = """
        one: 1
        two: 2
        three: 3

        """

        dict["one"] = "1"
        dict["two"] = "2"
        dict["three"] = "3"

        XCTAssertEqual(dict.description, testDesc)
    }
}
