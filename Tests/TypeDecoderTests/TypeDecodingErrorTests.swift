import Foundation
import XCTest
@testable import TypeDecoder

class TypeDecodingErrorTests: XCTestCase {

    static var allTests = [
        ("testDecodeErrorSingle", testDecodeErrorSingle),
        ("testDecodeErrorValidSingle", testDecodeErrorValidSingle),
        ("testDecodeValidSingleSuccess", testDecodeValidSingleSuccess),
        ("testDecodeErrorKeyed", testDecodeErrorKeyed),
        ("testDecodeErrorValidKeyed", testDecodeErrorValidKeyed),
        ("testDecodeValidKeyedSuccess", testDecodeValidKeyedSuccess),
    ]

    // A simple Codable enum with String raw value. The TypeDecoder cannot
    // handle this as-is, and decoding is expected to fail.
    enum CodableEnum: String, Codable {
        case foo,bar
    }

    // A simple Codable enum with String raw value, with conformance to
    // ValidSingleCodingValueProvider in order to provide a value. The value
    // provided in this case is invalid (decoding should fail).
    enum CodableValidEnumFail: String, Codable, ValidSingleCodingValueProvider {
        case foo,bar
        static func validCodingValue() -> Any? {
            return "fail"
        }
    }

    // A simple Codable enum with String raw value, with conformance to
    // ValidSingleCodingValueProvider in order to provide a value. The value
    // provided in this case is acceptable (decoding should succeed).
    enum CodableValidEnum: String, Codable, ValidSingleCodingValueProvider {
        case foo,bar
        static func validCodingValue() -> Any? {
            return self.foo.rawValue
        }
    }

    // A Codable struct with a validated String field. The TypeDecoder cannot
    // handle this as-is, and decoding is expected to fail.
    struct CodableKeyed: Codable {
        let foo: String
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.foo = try container.decode(String.self, forKey: CodingKeys.foo)
            guard self.foo == "Foo" else {
                throw DecodingError.dataCorruptedError(forKey: CodingKeys.foo, in: container, debugDescription: "Not Foo")
            }
        }
    }

    // A Codable struct with a validated String field, with conformance to
    // ValidKeyedCodingValueProvider in order to provide a value. The value
    // provided in this case is invalid (decoding should fail).
    struct CodableValidKeyedFail: Codable, ValidKeyedCodingValueProvider {
        static func validCodingValue(forKey key: CodingKey) -> Any? {
            return "Bar"
        }

        let foo: String
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.foo = try container.decode(String.self, forKey: CodingKeys.foo)
            guard self.foo == "Foo" else {
                throw DecodingError.dataCorruptedError(forKey: CodingKeys.foo, in: container, debugDescription: "Not Foo")
            }
        }
    }

    // A Codable struct with a validated String field, with conformance to
    // ValidKeyedCodingValueProvider in order to provide a value. The value
    // provided in this case is acceptable (decoding should succeed).
    struct CodableValidKeyed: Codable, ValidKeyedCodingValueProvider {
        static func validCodingValue(forKey key: CodingKey) -> Any? {
            switch key.stringValue {
            case self.CodingKeys.foo.stringValue:
                return "Foo"
            default:
                return nil
            }
        }

        let foo: String
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.foo = try container.decode(String.self, forKey: CodingKeys.foo)
            guard self.foo == "Foo" else {
                throw DecodingError.dataCorruptedError(forKey: CodingKeys.foo, in: container, debugDescription: "Not Foo")
            }
        }
    }

    // Test that decoding a SingleValue type which performs validation
    // fails with a TypeDecodingError with Symptom.noValueProvided
    func testDecodeErrorSingle() {
        do {
            let typeInfo = try TypeDecoder.decode(CodableEnum.self)
            XCTFail("Expected a TypeDecodingError but unexpectedly succeeded: \(typeInfo.debugDescription)")
        } catch let error as TypeDecodingError {
            XCTAssertEqual(error.symptom, TypeDecodingError.Symptom.noValueProvided)
        } catch {
            XCTFail("Expected a TypeDecodingError but received: \(error)")
        }
    }

    // Test that decoding a SingleValue type which performs validation,
    // and provides an invalid dummy value via ValidSingleCodingValueProvider
    // fails with a TypeDecodingError with Symptom.invalidSingleValue
    func testDecodeErrorValidSingle() {
        do {
            let typeInfo = try TypeDecoder.decode(CodableValidEnumFail.self)
            XCTFail("Expected a TypeDecodingError but unexpectedly succeeded: \(typeInfo.debugDescription)")
        } catch let error as TypeDecodingError {
            XCTAssertEqual(error.symptom, TypeDecodingError.Symptom.invalidSingleValue)
        } catch {
            XCTFail("Expected a TypeDecodingError but received: \(error)")
        }
    }

    // Test that decoding a SingleValue type which performs validation,
    // and provides an acceptable dummy value via ValidSingleCodingValueProvider
    // succeeds.
    func testDecodeValidSingleSuccess() {
        do {
            let typeInfo = try TypeDecoder.decode(CodableValidEnum.self)
            XCTAssertEqual(typeInfo, .single(String.self, String.self))
        } catch {
            XCTFail("Expected decoding to succeed, but received: \(error)")
        }
    }

    // Test that decoding a Keyed type which performs validation fails
    // with a TypeDecodingError with Symptom.noValueProvided
    func testDecodeErrorKeyed() {
        do {
            let typeInfo = try TypeDecoder.decode(CodableKeyed.self)
            XCTFail("Expected a TypeDecodingError but unexpectedly succeeded: \(typeInfo.debugDescription)")
        } catch let error as TypeDecodingError {
            XCTAssertEqual(error.symptom, TypeDecodingError.Symptom.noValueProvided)
        } catch {
            XCTFail("Expected a TypeDecodingError but received: \(error)")
        }
    }

    // Test that decoding a Keyed type which performs validation, and
    // provides an invalid dummy value via ValidKeyedCodingValueProvider
    // fails with a TypeDecodingError with Symptom.invalidKeyedValue
    func testDecodeErrorValidKeyed() {
        do {
            let typeInfo = try TypeDecoder.decode(CodableValidKeyedFail.self)
            XCTFail("Expected a TypeDecodingError but unexpectedly succeeded: \(typeInfo.debugDescription)")
        } catch let error as TypeDecodingError {
            XCTAssertEqual(error.symptom, TypeDecodingError.Symptom.invalidKeyedValue)
        } catch {
            XCTFail("Expected a TypeDecodingError but received: \(error)")
        }
    }

    // Test that decoding a Keyed type which performs validation, and
    // provides an acceptable dummy value via ValidKeyedCodingValueProvider
    // succeeds.
    func testDecodeValidKeyedSuccess() {
        do {
            let typeInfo = try TypeDecoder.decode(CodableValidKeyed.self)
            switch typeInfo {
            case .keyed(let type, _):
                XCTAssertTrue(type is CodableValidKeyed.Type, "Expected type to be \(CodableValidKeyed.self) but was: \(type)")
            default:
                XCTFail("Expected decode of keyed type, but was: \(typeInfo.debugDescription)")
            }
        } catch {
            XCTFail("Expected decoding to succeed, but received: \(error)")
        }
    }

}
