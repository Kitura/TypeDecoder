import XCTest
@testable import TypeDecoderTests

XCTMain([
    testCase(TypeDecoderTests.allTests),
    testCase(OrderedDictionaryTests.allTests),
])
