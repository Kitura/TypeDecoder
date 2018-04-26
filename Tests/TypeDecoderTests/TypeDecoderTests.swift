import Foundation
import XCTest
@testable import TypeDecoder

class TypeDecoderTests: XCTestCase {

    struct TestStruct: Decodable {
        let id: Int
        let name: String
        let cyclicArray: [TestStruct]
        let dynamicKeyed: [String:Int]
        let optionalWrapped: Float?
    }

    class TestClass: Decodable {
        let id: Int
        let name: String
        let dynamicKeyed: [String:Int]
        let optionalWrapped: Float?
    }

    static var allTests = [
        ("testNativeTypeDecoding", testNativeTypeDecoding),
        ("testFoundationTypeDecoding", testFoundationTypeDecoding),
        ("testCollectionTypeDecoding", testCollectionTypeDecoding),
        ("testKeyedStructureTypeDecoding", testKeyedStructureTypeDecoding),
        ("testKeyedClassTypeDecoding", testKeyedClassTypeDecoding),
        ("testUnkeyedArrayTypeDecoding", testUnkeyedArrayTypeDecoding),
        ("testCyclicStructureTypeDecoding", testCyclicStructureTypeDecoding),
        ("testDynamicKeyedStructureTypeDecoding", testDynamicKeyedStructureTypeDecoding),
        ("testOptionalTypeDecodingtest", testOptionalTypeDecoding),
    ]

    func testNativeTypeDecoding() {
        // Test TypeDecoder can decode all native types.
        var typeDict = Dictionary<String, Decodable.Type>()
        typeDict["Bool"] = Bool.self
        typeDict["Double"] = Double.self
        typeDict["Float"] = Float.self
        typeDict["Float"] = Float32.self
        typeDict["Double"] = Float64.self
        typeDict["Int"] = Int.self
        typeDict["UInt"] = UInt.self
        typeDict["Int8"] = Int8.self
        typeDict["UInt8"] = UInt8.self
        typeDict["Int16"] = Int16.self
        typeDict["UInt16"] = UInt16.self
        typeDict["Int32"] = Int32.self
        typeDict["UInt32"] = UInt32.self
        typeDict["Int64"] = Int64.self
        typeDict["UInt64"] = UInt64.self
        typeDict["String"] = String.self

        for (n, t) in typeDict {
            // let t = try! TypeDecoder.decode(t as! Decodable.Type)
            let t = try! TypeDecoder.decode(t)
            XCTAssertEqual(String(describing: t.self), n)
        }
    }

    func testFoundationTypeDecoding() {
        // Test TypeDecoder can decode Foundation types types.
        // The following were unable to be decoded:
        //
        // Calendar
        // DateComponents
        // DateInterval
        // Measurement
        // Notification
        // URLComponents
        // URLRequest

        func testPersonNameComponents() {
            // Test TypeDecoder can decode keyed structures.
            var result = false
            let t = try! TypeDecoder.decode(PersonNameComponents.self)
            if case .keyed(_, let dict) = t {
                if let _ = dict["familyName"],
                   let _ = dict["givenName"],
                   let _ = dict["middleName"],
                   let _ = dict["namePrefix"],
                   let _ = dict["nickname"],
                   let _ = dict["nameSuffix"] {
                    result = true
                }
            }
            XCTAssertEqual(true, result)
        }

        func testURLComponents() {
            // Test TypeDecoder can decode keyed structures.
            var result = false
            let t = try! TypeDecoder.decode(URL.self)
            if case .keyed(_, let dict) = t {
                if let _ = dict["relative"],
                   let _ = dict["base"] {
                    result = true
                }
            }
            XCTAssertEqual(true, result)
        }

        XCTAssertEqual(String(describing: try! TypeDecoder.decode(AffineTransform.self)), "[Double]")

        let charSetString = """
        CharacterSet{
          bitmap: [UInt8]
        }
        """
        XCTAssertEqual(String(describing: try! TypeDecoder.decode(CharacterSet.self)), charSetString)

        XCTAssertEqual(String(describing: try! TypeDecoder.decode(Date.self)), "Double")
        XCTAssertEqual(String(describing: try! TypeDecoder.decode(Decimal.self)), "[UInt16]")
        XCTAssertEqual(String(describing: try! TypeDecoder.decode(IndexPath.self)), "[Int]")

        let indexSetString = """
        IndexSet{
          location: Int,
          length: Int
        }
        """
        XCTAssertEqual(String(describing: try! TypeDecoder.decode(IndexSet.self)), indexSetString)

        let localeString = """
        Locale{
          identifier: String
        }
        """
        XCTAssertEqual(String(describing: try! TypeDecoder.decode(Locale.self)), localeString)
        testPersonNameComponents()

        let timeZoneString = """
        TimeZone{
          identifier: String
        }
        """
        XCTAssertEqual(String(describing: try! TypeDecoder.decode(TimeZone.self)), timeZoneString)

        testURLComponents()

        let URLString = """
        URL{
          relative: String,
          base: URL{<cyclic>}?
        }
        """
        XCTAssertEqual(String(describing: try! TypeDecoder.decode(URL.self)), URLString)

        XCTAssertEqual(String(describing: try! TypeDecoder.decode(UUID.self)), "String")
    }

    func testCollectionTypeDecoding() {
        // Test TypeDecoder can decode basic collection types.
        var typeDict = Dictionary<String, Any.Type>()
        typeDict["[String:String]"] = Dictionary<String,String>.self
        typeDict["[Bool]"] = Array<Bool>.self
        typeDict["[Int]"] = Set<Int>.self

        for (name, type) in typeDict {
            let t = try! TypeDecoder.decode(type as! Decodable.Type)
            XCTAssertEqual(String(describing: t.self), name, String(describing: t.self))
        }
    }

    func testKeyedStructureTypeDecoding() {
        // Test TypeDecoder can decode keyed structures.
        let keys = ["id", "name", "cyclicArray", "dynamicKeyed", "optionalWrapped"]
        let values = ["Int", "String", "[TestStruct{<cyclic>}]", "[String:Int]", "Float?"]
        let t = try! TypeDecoder.decode(TestStruct.self)
        if case .keyed(_, let dict) = t {
            var count = 0
            for (k, v) in dict {
                if keys[count] != k {
                    XCTFail("key: \(keys[count]) not found or in wrong position")
                } else if values[count] != String(describing: v) {
                    XCTFail("value: \(values[count]) not found or in wrong position")
                }
                count += 1
            }
        }
    }

    func testKeyedClassTypeDecoding() {
        // Test TypeDecoder can decode keyed class structures.
        let keys = ["id", "name", "dynamicKeyed", "optionalWrapped"]
        let values = ["Int", "String", "[String:Int]", "Float?"]
        let t = try! TypeDecoder.decode(TestClass.self)
        if case .keyed(_, let dict) = t {
            var count = 0
            for (k, v) in dict {
                if keys[count] != k {
                    XCTFail("key: \(keys[count]) not found or in wrong position")
                } else if values[count] != String(describing: v) {
                    XCTFail("value: \(values[count]) not found or in wrong position")
                }
                count += 1
            }
        }
    }

    func testUnkeyedArrayTypeDecoding() {
        // Test TypeDecoder can decode unKeyed types.
        var result = false
        let unkeyed = [String]()
        let t = try! TypeDecoder.decode(type(of: unkeyed))
        if case .unkeyed(_) = t {
            result = true
        }
        XCTAssertEqual(true, result)
    }

    func testCyclicStructureTypeDecoding() {
        // Test TypeDecoder can decode a cyclic (self referential) type.
        var result = ""
        let t = try! TypeDecoder.decode(TestStruct.self)
        if case .keyed(_, let dict) = t {
            if let cyclicArray = dict["cyclicArray"] {
                if case .unkeyed(_, let valueType) = cyclicArray {
                    if case .cyclic(let value) = valueType {
                        result = String(describing: value)
                    }
                }
            }
        }
        XCTAssertEqual("TestStruct", result)
    }

    func testDynamicKeyedStructureTypeDecoding() {
        // Test TypeDecoder can decode a dynamic keyed (Dictionary) type.
        var result = false
        let t = try! TypeDecoder.decode(TestStruct.self)

        if case .keyed(_, let dict) = t {
            if let dynamicKeyed = dict["dynamicKeyed"] {
                if case .dynamicKeyed(_, let key, let value) = dynamicKeyed {
                    if case .single(_, let keyType) = key, case .single(_, let valueType) = value {
                        if keyType == String.self && valueType == Int.self {
                            result = true
                        }
                    }
                }
            }
        }
        XCTAssertEqual(true, result)
    }

    func testOptionalTypeDecoding() {
        // Test TypeDecoder can decode an optional wrapped type.
        var result = false
        let t = try! TypeDecoder.decode(TestStruct.self)

        if case .keyed(_, let dict) = t {
            if let optionalWrapped = dict["optionalWrapped"] {
                if case .optional(let valueType) = optionalWrapped {
                    if case .single(_, let valueType) = valueType {
                        if valueType == Float.self {
                            result = true
                        }
                    }
                }
            }
        }
        XCTAssertEqual(true, result)
    }
}
