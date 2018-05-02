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
        ("testOptionalTypeDecodingtest", testOptionalTypeDecoding)
    ]

    func assertOptionalString(_ testType: TypeInfo) {
        if case .optional(let wrapped) = testType {
            if case .single(_, let decodedType) = wrapped {
                XCTAssert(String.self == decodedType)
            } else {
                XCTFail("should have decoded a .single")
            }
        } else {
            XCTFail("should have decoded a .optional")
        }
    }

    func testNativeTypeDecoding() {
        func nativeTypeDecoding() throws {
            // Test TypeDecoder can decode all native types.
            var typeArray = [Decodable.Type]()
            typeArray.append(Bool.self)
            typeArray.append(Double.self)
            typeArray.append(Float.self)
            typeArray.append(Float32.self)
            typeArray.append(Float64.self)
            typeArray.append(Int.self)
            typeArray.append(UInt.self)
            typeArray.append(Int8.self)
            typeArray.append(UInt8.self)
            typeArray.append(Int16.self)
            typeArray.append(UInt16.self)
            typeArray.append(Int32.self)
            typeArray.append(UInt32.self)
            typeArray.append(Int64.self)
            typeArray.append(UInt64.self)
            typeArray.append(String.self)

            for knownType in typeArray {
                if case .single(_, let decodedType) = try TypeDecoder.decode(knownType) {
                    XCTAssert(knownType == decodedType)
                } else {
                    XCTFail("should have decoded a .single")
                }
            }
        }
        XCTAssertNoThrow(try nativeTypeDecoding())
    }

    func testFoundationTypeDecoding() throws {
        // Test TypeDecoder can decode Foundation types types.
        // The following are all internal to foundation and could
        // not be accessed. They could not be decoded: 
        //
        // Calendar
        // DateComponents
        // DateInterval
        // Measurement
        // Notification
        // URLComponents
        // URLRequest

        @available(OSX 10.11, *)
        func testPersonNameComponents() throws {
            var result = false
            let t = try TypeDecoder.decode(PersonNameComponents.self)
            if case .keyed(_, let dict) = t {
                if let familyName = dict["familyName"],
                   let givenName = dict["givenName"],
                   let middleName = dict["middleName"],
                   let namePrefix = dict["namePrefix"],
                   let nickName = dict["nickname"],
                   let nameSuffix = dict["nameSuffix"] {
                       assertOptionalString(familyName)
                       assertOptionalString(givenName)
                       assertOptionalString(middleName)
                       assertOptionalString(namePrefix)
                       assertOptionalString(nickName)
                       assertOptionalString(nameSuffix)
                    result = true
                }
            }
            XCTAssertEqual(true, result)
        }

        func testAffineTransform() throws {
            // test AffineTransform type is [Double]
            if case .unkeyed(_, let elementTypeInfo) = try TypeDecoder.decode(AffineTransform.self) {
                if case .single(_, let decodedType) = elementTypeInfo {
                    XCTAssert(Double.self == decodedType)
                } else {
                    XCTFail("should have decoded a .single")
                }
            } else {
                XCTFail("should have decoded a .keyed")
            }
        }

        func testCharacterSet() throws {
            // CharacterSet{
            //   bitmap: [UInt8]
            // }
            if case .keyed(_, let dict) = try TypeDecoder.decode(CharacterSet.self) {
                if let bitmap = dict["bitmap"] {
                    if case .unkeyed(_, let elementTypeInfo) = bitmap {
                        if case .single(_, let decodedType) = elementTypeInfo {
                            XCTAssert(UInt8.self == decodedType)
                        } else {
                            XCTFail("should have decoded a .single")
                        }
                    } else {
                        XCTFail("should have decoded an .unkeyed")
                    }
                } else {
                    XCTFail("should have found an entry for \"bitmap\"")
                }
            } else {
                XCTFail("should have decoded a .keyed")
            }
        }

        func testDouble() throws {
            // test type is Double
            if case .single(_, let decodedType) = try TypeDecoder.decode(Double.self) {
                XCTAssert(Double.self == decodedType)
            } else {
                XCTFail("should have decoded a .single")
            }
        }

        func testArrayUInt16() throws {
            // test type is [UInt16]
            if case .unkeyed(_, let elementTypeInfo) = try TypeDecoder.decode(Array<UInt16>.self) {
                if case .single(_, let decodedType) = elementTypeInfo {
                    XCTAssert(UInt16.self == decodedType)
                } else {
                    XCTFail("should have decoded a .single")
                }
            } else {
                XCTFail("should have decoded an .unkeyed")
            }
        }

        func testInt() throws {
            // test type is Int
            if case .single(_, let decodedType) = try TypeDecoder.decode(Int.self) {
                XCTAssert(Int.self == decodedType)
            } else {
                XCTFail("should have decoded a .single")
            }
        }

        func testIndexSet() throws {
            // IndexSet{
            //   location: Int,
            //   length: Int
            // }
            if case .keyed(_, let dict) = try TypeDecoder.decode(IndexSet.self) {
                if let location = dict["location"] {
                    if case .single(_, let decodedType) = location {
                        XCTAssert(Int.self == decodedType)
                    } else {
                        XCTFail("should have decoded a .single")
                    }
                } else {
                    XCTFail("should have found an entry for \"location\"")
                }
                if let length = dict["length"] {
                    if case .single(_, let decodedType) = length {
                        XCTAssert(Int.self == decodedType)
                    } else {
                        XCTFail("should have decoded a .single")
                    }
                } else {
                    XCTFail("should have found an entry for \"length\"")
                }
            } else {
                XCTFail("should have decoded a .keyed")
            }
        }

        func testLocale() throws {
            // Locale{
            //   identifier: String
            // }
            if case .keyed(_, let dict) = try TypeDecoder.decode(Locale.self) {
                if let identifier = dict["identifier"] {
                    if case .single(_, let decodedType) = identifier {
                        XCTAssert(String.self == decodedType)
                    } else {
                        XCTFail("should have decoded a .single")
                    }
                } else {
                    XCTFail("should have found an entry for \"identifier\"")
                }
            } else {
                XCTFail("should have decoded a .keyed")
            }
        }


        func testTimeZone() throws {
            // TimeZone{ 
            //   identifier: String
            // }
            if case .keyed(_, let dict) = try TypeDecoder.decode(TimeZone.self) {
                if let identifier = dict["identifier"] {
                    if case .single(_, let decodedType) = identifier {
                        XCTAssert(String.self == decodedType)
                    } else {
                        XCTFail("should have decoded a .single")
                    }
                } else {
                    XCTFail("should have found an entry for \"identifier\"")
                }
            } else {
                XCTFail("should have decoded a .keyed")
            }
        }

        func testURL() throws {
            // URL{
            //   relative: String,
            //   base: URL{<cyclic}?
            // }
            if case .keyed(_, let dict) = try TypeDecoder.decode(URL.self) {
                if let relative = dict["relative"] { 
                    if case .single(_, let decodedType) = relative {
                        XCTAssert(String.self == decodedType)
                    } else {
                        XCTFail("should have decoded a .single")
                    }
                } else {
                    XCTFail("should have found an entry for \"relative\"")
                }
                if let base = dict["base"] { 
                    if case .optional(let optionalType) = base {
                        if case .cyclic(let cyclicType) = optionalType {
                            XCTAssert(URL.self == cyclicType)
                        } else {
                            XCTFail("should have decoded a .cyclic")
                        }
                    } else {
                        XCTFail("should have decoded a .optional")
                    }
                } else {
                    XCTFail("should have found an entry for \"base\"")
                }
            } else {
                XCTFail("should have decoded a .keyed")
            }
        }

        func testUUID() throws {
            // test type is UUID (String)
            if case .single(_, let decodedType) = try TypeDecoder.decode(UUID.self) {
                XCTAssert(String.self == decodedType)
            } else {
                XCTFail("should have decoded a .single")
            }
        }

        XCTAssertNoThrow(try testAffineTransform())
        if #available(OSX 10.11, *) {
            XCTAssertNoThrow(try testPersonNameComponents())
        }
        XCTAssertNoThrow(try testCharacterSet())
        XCTAssertNoThrow(try testDouble())
        XCTAssertNoThrow(try testArrayUInt16())
        XCTAssertNoThrow(try testInt())
        XCTAssertNoThrow(try testIndexSet())
        XCTAssertNoThrow(try testLocale())
        XCTAssertNoThrow(try testTimeZone())
        XCTAssertNoThrow(try testURL())
        XCTAssertNoThrow(try testUUID())
    }

    func testCollectionTypeDecoding() throws {
        func collectionTypeDecoding() throws {
            // Test TypeDecoder can decode basic collection types.
            var typeArray = Array<Decodable.Type>()
            typeArray.append(Dictionary<String,String>.self)
            typeArray.append(Array<Bool>.self)
            typeArray.append(Set<Int>.self)

            for knownType in typeArray {
                if case .dynamicKeyed(_, let keyTypeInfo, let valueTypeInfo) = try TypeDecoder.decode(knownType) {
                    if knownType == Dictionary<String,String>.self {
                        if case .single(_, let keyType) = keyTypeInfo {
                            XCTAssert(keyType == String.self)
                        } else {
                            XCTFail("dictionary returned incorrect key type")
                        }
                        if case .single(_, let valueType) = valueTypeInfo {
                            XCTAssert(valueType == String.self)
                        } else {
                            XCTFail("dictionary returned incorrect value type")
                        }
                    } else {
                        XCTFail("invalid type is interpreted as dynamicKeyed")
                    }
                }
                if case .unkeyed(_, let elementTypeInfo) = try TypeDecoder.decode(knownType) {
                    if knownType == Array<Bool>.self {
                        if case .single(_, let decodedType) = elementTypeInfo {
                            XCTAssert(decodedType == Bool.self)
                        } else {
                            XCTFail("Array type returned incorrect contained type")
                        }
                    } else if knownType == Set<Int>.self {
                        if case .single(_, let decodedType) = elementTypeInfo {
                            XCTAssert(decodedType == Int.self)
                        } else {
                            XCTFail("Set type returned incorrect contained type")
                        }
                    } else {
                        XCTFail("invalid type is interpreted as unkeyed")
                    }
                }
            }
        }
        XCTAssertNoThrow(try testCollectionTypeDecoding())
    }

    func testKeyedStructureTypeDecoding() {
        func keyedStructureTypeDecoding() throws {
            // Test TypeDecoder can decode keyed structures.
            let keys = ["id", "name", "cyclicArray", "dynamicKeyed", "optionalWrapped"]
            let values = ["Int", "String", "[TestStruct{<cyclic>}]", "[String:Int]", "Float?"]
            let t = try TypeDecoder.decode(TestStruct.self)
            if case .keyed(_, let dict) = t {
                var count = 0
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
        }

        XCTAssertNoThrow(try keyedStructureTypeDecoding())
    }

    func testKeyedClassTypeDecoding() {
        func keyedClassTypeDecoding() throws {
            // Test TypeDecoder can decode keyed class structures.
            let keys = ["id", "name", "dynamicKeyed", "optionalWrapped"]
            let values = ["Int", "String", "[String:Int]", "Float?"]
            let t = try TypeDecoder.decode(TestClass.self)
            if case .keyed(_, let dict) = t {
                var count = 0
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
        }

        XCTAssertNoThrow(try keyedClassTypeDecoding())
    }

    func testUnkeyedArrayTypeDecoding() {
        func unkeyedArrayTypeDecoding() throws {
            // Test TypeDecoder can decode unKeyed types.
            if case .unkeyed(_, let elementTypeInfo) = try TypeDecoder.decode([String].self) {                    
                if case .single(_, let decodedType) = elementTypeInfo {
                    XCTAssert(decodedType == String.self)
                } else {
                    XCTFail("should have decoded a .single")
                }
            } else {
                XCTFail("should have decoded an .unkeyed")
            }
        }
        XCTAssertNoThrow(try unkeyedArrayTypeDecoding())
    }

    func testCyclicStructureTypeDecoding() {
        func cyclicStructureTypeDecoding() throws {
            // Test TypeDecoder can decode a cyclic (self referential) type.
            let t = try TypeDecoder.decode(TestStruct.self)
            if case .keyed(_, let dict) = t {
                if let cyclicArray = dict["cyclicArray"] {
                    if case .unkeyed(_, let valueType) = cyclicArray {
                        if case .cyclic(let value) = valueType {
                            XCTAssert(value == TestStruct.self)
                        } else {
                            XCTFail("should have decoded a .cyclic")
                        }
                    } else {
                        XCTFail("should have decoded a .unkeyed")
                    }
                } else {
                    XCTFail("should have found an entry for \"cyclicArray\"")
                }
            }
        }
        XCTAssertNoThrow(try cyclicStructureTypeDecoding())
    }

    func testDynamicKeyedStructureTypeDecoding() {
        func dynamicKeyedStructureTypeDecoding() throws {
            // Test TypeDecoder can decode a dynamic keyed (Dictionary) type.
            var result = false
            let t = try TypeDecoder.decode(TestStruct.self)

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
        XCTAssertNoThrow(try dynamicKeyedStructureTypeDecoding())
    }

    func testOptionalTypeDecoding() {
        func optionalTypeDecoding() throws {
            // Test TypeDecoder can decode an optional wrapped type.
            var result = false
            let t = try TypeDecoder.decode(TestStruct.self)

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
        XCTAssertNoThrow(try optionalTypeDecoding())
    }
}
