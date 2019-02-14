/*
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Foundation

struct InternalError: Error {
    let message: String
    init(_ message: String) {
        self.message = message
    }
}

/// Protocol and extension for detecting type erased dictionaries
/// and extracting their Key and Vaue types
protocol DictionaryType {
    static func getKeyType() -> Any.Type
    static func getValueType() -> Any.Type
}
extension Dictionary: DictionaryType {
    static func getKeyType() -> Any.Type { return Key.self }
    static func getValueType() -> Any.Type { return Value.self }
}

// MARK: Validation

/**
 A protocol that your Codable type can adopt, in order to supply values
 for fields that are validated during decoding.

 The TypeDecoder operates by constructing a 'dummy' instance of a type,
 via the `init(from: Decoder)` initializer. As there is no real data to
 be decoded, dummy values (such as `0` and `""`) are provided. This
 may cause an initializer that requires specific valid values to fail.

 To enable such a type to work with TypeDecoder, define an extension
 that conforms the type to the `ValidKeyedCodingValueProvider` protocol.
 The `validCodingValue(forKey:)` function should return a valid value
 for fields that requires validation.

 ### Usage Example: ###
 ```swift
 public class YoungAdult: Codable {
     let name: String
     let age: Int
     required public init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         self.name = try container.decode(String.self, forKey: CodingKeys.name)
         self.age = try container.decode(Int.self, forKey: CodingKeys.age)
         // Validate the age field
         guard self.age >= 18, self.age <= 30 else {
             throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Age is outside the permitted range"))
         }
     }
 }

 // Provide a value for 'age' which is within the acceptable range
 extension YoungAdult: ValidKeyedCodingValueProvider {
     public static func validCodingValue(forKey key: CodingKey) -> Any? {
         switch key.stringValue {
         case self.CodingKeys.age.stringValue:
             return 20
         default:
             // For any fields that are not validated, you may return nil.
             // The TypeDecoder will use a standard dummy value.
             return nil
         }
     }
 }
 ```
 */
public protocol ValidKeyedCodingValueProvider {

    /// Returns a value for a `CodingKey` that represents a field that
    /// requires validation. `nil` may be returned for all other fields.
    ///
    /// ### Usage Example: ###
    /// ```swift
    /// switch key.stringValue {
    /// case self.CodingKeys.email.stringValue:
    ///     return "joe@example.com"
    /// default:
    ///     return nil
    /// }
    /// ```
    static func validCodingValue(forKey: CodingKey) -> Any?
}

/**
 A protocol that your Codable type can adopt, in order to supply a
 valid value during decoding. This protocol is suitable for types that
 are represented by a single encoded value, such as an enum.

 The TypeDecoder operates by constructing a 'dummy' instance of a type,
 via the `init(from: Decoder)` initializer. As there is no real data to
 be decoded, a dummy value (such as `0` or `""`) is provided. This
 may cause an initializer that requires a specific valid value to fail.

 To enable such a type to work with TypeDecoder, define an extension
 that conforms the type to the `ValidSingleCodingValueProvider` protocol.
 The `validCodingValue()` function should return a valid encoded
 representation of that type.

 ### Usage Example: ###
 ```swift
 public enum Fruit: String, Codable {
     case apple, banana, orange, pear
 }

 // Provide an acceptable value during decoding
 extension Fruit: ValidSingleCodingValueProvider {
     public static func validCodingValue() -> Any? {
         // Returns the string "apple"
         return self.apple.rawValue
     }
 }
 ```
 */
public protocol ValidSingleCodingValueProvider {

    /// Returns a valid encoded representation of the conforming type.
    ///
    /// ### Usage Example: ###
    /// ```swift
    ///     self.apple.rawValue
    /// ```
    static func validCodingValue() -> Any?
}

/// Extension of the `URL` Foundation class that has validations to provide
/// valid dummy values.
extension URL: ValidKeyedCodingValueProvider {
    public static func validCodingValue(forKey key: CodingKey) -> Any? {
        switch key.intValue {
        case 1?: return "http://example.com/"
        default: return nil
        }
    }
}
/// Extension of the `TimeZone` Foundation class that has validations to provide
/// valid dummy values.
extension TimeZone: ValidKeyedCodingValueProvider {
    public static func validCodingValue(forKey key: CodingKey) -> Any? {
        switch key.intValue {
        case 0?: return TimeZone.current.identifier
        default: return nil
        }
    }
}
/// Extension of the `UUID` Foundation class that has validations to provide
/// valid dummy values.
extension UUID: ValidSingleCodingValueProvider {
    public static func validCodingValue() -> Any? {
        return UUID().uuidString
    }
}

// MARK: TypeInfo

/// Main enum used to describe a decoded type.
public indirect enum TypeInfo {
    /// Case representing a simple type, such as a String, which is not recursive.
    ///
    /// Two types associated with this case: top level and low level.
    ///
    /// ### Usage Example: ###
    /// ```
    /// String - single(String.Type, String.Type)
    /// URL - single(URL.Type, String.Type)
    /// ```
    case single(Any.Type, Any.Type)

    /// Case representing a struct or a class containing the object type as
    /// `Any.Type` and its nested types as an `OrderedDictionary`.
    ///
    /// ### Usage Example: ###
    /// ```swift
    /// struct User: Codable {
    ///   let name: String
    ///   let age: Int
    /// }
    /// .keyed(User.Type, ["name": .single(String.Type, String.Type), "age": .single(Int.Type, Int.Type)]
    /// ```
    case keyed(Any.Type, OrderedDictionary<String, TypeInfo>)

    /// Case representing a Dictionary containing the top level type of the
    /// Dictionary, the type of the key and the type of the value.
    ///
    /// ### Usage Example: ###
    /// ```
    /// [String: Int] -- .dynamicKeyed(Dictionary<String, Int>.Type, key: .single(String.Type, String.Type), value: .single(Int.Type, Int.Type))
    /// ```
    case dynamicKeyed(Any.Type, key: TypeInfo, value: TypeInfo)

    /// Case representing an Array containing the top level type of the array
    /// and its nested type.
    ///
    /// ### Usage Example: ###
    /// ```
    /// [String] -- .unkeyed(Array<String>.Type, .single(String.Type, String.Type))
    /// ```
    case unkeyed(Any.Type, TypeInfo)

    /// Case representing an Optional type containing its nested type.
    ///
    /// ### Usage Example: ###
    /// ```
    /// String? -- .optional(.single(String.Type, String.Type))
    /// ```
    case optional(TypeInfo)


    /// Case representing a cyclic type so the associated type is the top level type.
    ///
    /// ### Usage Example: ###
    /// ```swift
    /// struct User: Codable {
    ///   let name: String
    ///   let friends: [User]
    /// }
    /// .keyed(User.Type, ["name": .single(String.Type, String.Type), "friends": .cyclic(User.Type)]
    /// ```
    case cyclic(Any.Type)

    /// Case representing a type that could not be decoded.
    case opaque(Any.Type)
}

/// Generates a `debugDescription` that describes the case of `self` and the type
/// information associated with that case. This description does not recurse down
/// into nested types.
extension TypeInfo: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .cyclic(let type):
            return ".cyclic: \(String(reflecting: type))"
        case .dynamicKeyed(_):
            return ".dynamicKeyed: \(self.description)"
        case .keyed(let original, _):
            return ".keyed: \(String(reflecting: original))"
        case .opaque(let type):
            return ".opaque: \(String(reflecting: type))"
        case .optional(let type):
            return ".optional: \(type.debugDescription)"
        case .single(_, let type):
            return ".single: \(String(reflecting: type))"
        case .unkeyed(_, let type):
            return ".unkeyed: \(type.debugDescription)"
        }
    }
}

/// Generates a `description` which is a human-readable representation of the structured
/// type information represented by `self`. This representation recurses into nested
/// types.
extension TypeInfo: CustomStringConvertible {
    public var description: String { return describeTypeInfo(self) }

    /// Function to pretty print a TypeInfo
    // TODO: Maybe add a few more bits of info to the output
    func describeTypeInfo(_ t: TypeInfo?, desc: String = "", indent: Int = 0) -> String {
        guard let t = t else { return "No type info" }
        let ind = String(repeating: " ", count: indent)
        let nextInd = String(repeating: " ", count: indent+2)
        switch t {
        case .keyed(let original, let properties):
            return desc + "\(original){\n\(properties.map({ (k,v) in nextInd + "\(k): \(describeTypeInfo(v, indent: indent + 2))"}).joined(separator: ",\n"))\n\(ind)}"
        case .dynamicKeyed(_ /*let original*/, let keyTypeInfo, let valueTypeInfo):
            return desc + "[\(describeTypeInfo(keyTypeInfo)):\(describeTypeInfo(valueTypeInfo, indent: indent + 2))]"
        case .unkeyed(_ /*let original*/, let elementTypeInfo):
            return desc + "[\(describeTypeInfo(elementTypeInfo, indent: indent))]"
        case .cyclic(let type):
            return desc + "\(type){<cyclic>}"
        case .single(_ /*let original*/, let type):
            return desc + "\(type)"
        case .optional(let wrappedTypeInfo):
            return desc + "\(describeTypeInfo(wrappedTypeInfo, indent: indent))?"
        case .opaque(let type):
            return desc + "<opaque: \(type)>"
        }
    }
}

extension TypeInfo: Hashable {
    #if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
    #else
    public var hashValue: Int {
        return description.hashValue
    }
    #endif
}

extension TypeInfo: Equatable {
    public static func == (lhs: TypeInfo, rhs: TypeInfo) -> Bool {
        return lhs.description == rhs.description
    }
}

/// An `Error` type indicating a problem during decoding by the `TypeDecoder`.
///
/// This type provides additional guidance for `Decodable` types that do not
/// conform to either the `ValidSingleCodingValueProvider` or `ValidKeyedCodingValueProvider`
/// protocols, suggesting that conformance may enable successful decoding.
public struct TypeDecodingError: Error {

    /// A description of the error and the underlying error, which is of type `DecodingError`.
    public let context: DecodingError.Context

    /// An indication of the type of failure associated with this error
    let symptom: Symptom

    /// A set of possible failure types for a TypeDecodingError
    enum Symptom: String {
        /// A type conforms to ValidSingleCodingValueProvider, but was unable to be decoded
        case invalidSingleValue
        /// A type conforms to ValidKeyedCodingValueProvider, but was unable to be decoded
        case invalidKeyedValue
        /// A type was unable to be decoded, and did not conform to a CodingValueProvider protocol
        case noValueProvided
    }

    // Describe decoding error, and suggest conformance to `ValidKeyedCodingValueProvider`
    // or `ValidSingleCodingValueProvider` if the type does not already conform to one of
    // those protocols.
    static func decodingError(decoding type: Decodable.Type, forKey key: CodingKey? = nil, underlyingError: Swift.DecodingError) -> TypeDecodingError {
        let codingPath: [CodingKey]
        let context: DecodingError.Context
        let symptom: Symptom
        if let key = key {
            codingPath = [key]
        } else {
            codingPath = []
        }
        if let _ = type as? ValidSingleCodingValueProvider.Type {
            // The user's type already provides unkeyed values, but decoding failed
            context = DecodingError.Context(codingPath: codingPath, debugDescription: "TypeDecoder was unable to decode single value type `\(type)`, confirm that the value supplied by `validCodingValue()` is valid.", underlyingError: underlyingError)
            symptom = .invalidSingleValue
        } else if let _ = type as? ValidKeyedCodingValueProvider.Type {
            // The user's type already provides keyed values, but decoding failed
            context = DecodingError.Context(codingPath: codingPath, debugDescription: "TypeDecoder was unable to decode keyed type `\(type)`, confirm that `validCodingValue(forKey:)` provides appropriate values for all validated fields.", underlyingError: underlyingError)
            symptom = .invalidKeyedValue
        } else {
            // The user's type does not supply valid values, suggest a course of action
            context = DecodingError.Context(codingPath: codingPath, debugDescription: "TypeDecoder was unable to decode type `\(type)`: conformance to `\(ValidKeyedCodingValueProvider.self)` or `\(ValidSingleCodingValueProvider.self)` may be required.", underlyingError: underlyingError)
            symptom = .noValueProvided
        }
        return TypeDecodingError(context: context, symptom: symptom)
    }
}

class InternalTypeDecoder: Decoder {
    let decodingType: Any.Type
    fileprivate var typePath: [Any.Type]
    fileprivate var typeInfo: TypeInfo

    init(_ type: Any.Type, typePath: [Any.Type]) throws {
        decodingType = type
        typeInfo = .opaque(decodingType)

        var newTypePath = typePath
        newTypePath.append(type)

        guard !typePath.contains(where: { $0 == type }) else {
            self.typePath = newTypePath
            typeInfo = .cyclic(type)
            return
        }
        self.typePath = newTypePath

        if let dictionaryType = decodingType as? DictionaryType.Type,
            let keyType = dictionaryType.getKeyType() as? Decodable.Type,
            let valueType = dictionaryType.getValueType() as? Decodable.Type {

            typeInfo = .dynamicKeyed(decodingType,
                                     key: try TypeDecoder.decodeInternal(keyType, typePath: typePath),
                                     value: try TypeDecoder.decodeInternal(valueType, typePath: typePath))

        }
    }

    public var codingPath: [CodingKey] { return [] }
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    var cyclic: Bool { if case .cyclic = typeInfo { return true } else { return false } }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        if case .opaque = typeInfo {
            return KeyedDecodingContainer(TypeKeyedDecodingContainer<Key>(self))
        } else {
            return KeyedDecodingContainer(DummyKeyedDecodingContainer<Key>(DummyDecoder(decodingType)))
        }
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        if case .opaque = typeInfo {
            return TypeUnkeyedDecodingContainer(self)
        } else {
            return DummyUnkeyedDecodingContainer(DummyDecoder(decodingType))
        }
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        if case .opaque = typeInfo {
            return TypeSingleValueDecodingContainer(self)
        } else {
            return DummySingleValueDecodingContainer(DummyDecoder(decodingType))
        }
    }
}

class TypeKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    var decoder: InternalTypeDecoder
    var optionalKeys = Set<String>()

    init(_ decoder: InternalTypeDecoder) {
        self.decoder = decoder
    }

    var codingPath: [CodingKey] { return [] }
    var allKeys: [Key] { return [] }

    func contains(_ key: Key) -> Bool { return true }

    private func keyDesc(_ key: Key) -> String {
        return "[\(key.stringValue):\(key.intValue ?? 0)]"
    }

    private func updateKeyedTypeInfo(with propertyTypeInfo: TypeInfo, forKey key: Key) throws {
        let info = optionalKeys.contains(keyDesc(key)) ? .optional(propertyTypeInfo) : propertyTypeInfo
        switch decoder.typeInfo {
        case .opaque:
            // Initialize
            var dict = OrderedDictionary<String, TypeInfo>()
            dict[key.stringValue] = info
            decoder.typeInfo = .keyed(decoder.decodingType, dict)
        case .keyed(let decodingType, var allPropertyTypeInfos) where decodingType == decoder.decodingType:
            // Add new property
            allPropertyTypeInfos[key.stringValue] = info
            decoder.typeInfo = .keyed(decoder.decodingType, allPropertyTypeInfos)
        default:
            // Something changed in an unexpected way
            assert(false)
            throw InternalError("Key type mismatch, expected .keyed(\(decoder.decodingType), ...), got \(String(describing: decoder.typeInfo))")
        }
    }

    func dummy<T>(forKey key: Key) -> T? {
        return (decoder.decodingType as? ValidKeyedCodingValueProvider.Type)?.validCodingValue(forKey: key) as? T
    }

    func decodeNil(forKey key: Key) throws -> Bool                     { optionalKeys.insert(keyDesc(key)); return decoder.cyclic }
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool     { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? false }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int       { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8     { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16   { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32   { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64   { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt     { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8   { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float   { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? 0 }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { try updateKeyedTypeInfo(with: .single(type, type), forKey: key); return dummy(forKey: key) ?? "" }
    func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let propertyInternalDecoder = try InternalTypeDecoder(type, typePath: decoder.typePath)
        do {
            let propertyValue = try T(from: propertyInternalDecoder)
            let propertyTypeInfo = propertyInternalDecoder.typeInfo
            try updateKeyedTypeInfo(with: propertyTypeInfo, forKey: key)
            return propertyValue
        } catch let error as DecodingError {
            // Customize the error, informing the user of validation requirements if appropriate
            throw TypeDecodingError.decodingError(decoding: T.self, forKey: key, underlyingError: error)
        }
    }
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        // FIXME
        return KeyedDecodingContainer(TypeKeyedDecodingContainer<NestedKey>(decoder))
    }
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        // FIXME
        return TypeUnkeyedDecodingContainer(decoder)
    }
    func superDecoder() throws -> Decoder {
        return try InternalTypeDecoder(decoder.decodingType, typePath: decoder.typePath) // FIXME
    }
    func superDecoder(forKey key: Key) throws -> Decoder {
        return try InternalTypeDecoder(decoder.decodingType, typePath: decoder.typePath) // FIXME
    }
}

class TypeSingleValueDecodingContainer: SingleValueDecodingContainer {
    var decoder: InternalTypeDecoder
    var isOptional = false

    init(_ decoder: InternalTypeDecoder) {
        self.decoder = decoder
    }

    var codingPath: [CodingKey] { return [] }

    private func setTypeInfo(to typeInfo: TypeInfo) {
        decoder.typeInfo = isOptional ? .optional(typeInfo) : typeInfo
    }

    func dummy<T>() -> T? {
        return (decoder.decodingType as? ValidSingleCodingValueProvider.Type)?.validCodingValue() as? T
    }

    func decodeNil() -> Bool                          { isOptional = true; return decoder.cyclic }
    func decode(_ type: Bool.Type) throws -> Bool     { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? false }
    func decode(_ type: Int.Type) throws -> Int       { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: Int8.Type) throws -> Int8     { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: Int16.Type) throws -> Int16   { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: Int32.Type) throws -> Int32   { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: Int64.Type) throws -> Int64   { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: UInt.Type) throws -> UInt     { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: UInt8.Type) throws -> UInt8   { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: Float.Type) throws -> Float   { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: Double.Type) throws -> Double { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? 0 }
    func decode(_ type: String.Type) throws -> String { setTypeInfo(to: .single(decoder.decodingType, type)); return dummy() ?? "" }
    func decode<T : Decodable>(_ type: T.Type) throws -> T {
        do {
            let internalDecoder = try InternalTypeDecoder(type, typePath: decoder.typePath)
            let value = try T(from: internalDecoder)
            let typeInfo = internalDecoder.typeInfo
            setTypeInfo(to: typeInfo)
            return value
        } catch let error as DecodingError {
            // Customize the error, informing the user of validation requirements if appropriate
            throw TypeDecodingError.decodingError(decoding: T.self, underlyingError: error)
        }
    }
}

struct TypeUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    var decoder: InternalTypeDecoder
    var isOptional = false

    init(_ decoder: InternalTypeDecoder) {
        self.decoder = decoder
        self.isAtEnd = decoder.cyclic
    }

    var codingPath: [CodingKey] { return [] }
    var count: Int? { return 1 }
    var isAtEnd: Bool
    var currentIndex = 0

    private func setTypeInfo(to typeInfo: TypeInfo) {
        decoder.typeInfo = .unkeyed(decoder.decodingType, isOptional ? .optional(typeInfo) : typeInfo)
    }

    mutating func decodeNil() throws -> Bool                   { isOptional = true; return decoder.cyclic }
    mutating func decode(_ type: Bool.Type) throws -> Bool     { isAtEnd = true; setTypeInfo(to: .single(type, type)); return false }
    mutating func decode(_ type: Int.Type) throws -> Int       { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: Int8.Type) throws -> Int8     { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: Int16.Type) throws -> Int16   { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: Int32.Type) throws -> Int32   { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: Int64.Type) throws -> Int64   { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: UInt.Type) throws -> UInt     { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8   { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: Float.Type) throws -> Float   { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: Double.Type) throws -> Double { isAtEnd = true; setTypeInfo(to: .single(type, type)); return 0 }
    mutating func decode(_ type: String.Type) throws -> String { isAtEnd = true; setTypeInfo(to: .single(type, type)); return "" }
    mutating func decode<T : Decodable>(_ type: T.Type) throws -> T {
        do {
            isAtEnd = true
            let internalDecoder = try InternalTypeDecoder(type, typePath: decoder.typePath)
            let value = try T(from: internalDecoder)
            let typeInfo = internalDecoder.typeInfo
            setTypeInfo(to: typeInfo)
            return value
        } catch let error as DecodingError {
            // Customize the error, informing the user of validation requirements if appropriate
            throw TypeDecodingError.decodingError(decoding: T.self, underlyingError: error)
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        // FIXME: Not implemented (dummy code just to keep the compiler happy)
        isAtEnd = true
        return KeyedDecodingContainer(TypeKeyedDecodingContainer<NestedKey>(decoder))
    }
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        // FIXME: Not implemented (dummy code just to keep the compiler happy)
        return TypeUnkeyedDecodingContainer(decoder)
    }
    mutating func superDecoder() throws -> Decoder {
        // FIXME: Not implemented (dummy code just to keep the compiler happy)
        isAtEnd = true
        return try InternalTypeDecoder(decoder.decodingType, typePath: decoder.typePath)
    }
}

// This decoder is for when we don't care about type information and just need to
// create a value of the decode type (used when we have already decoded the type
// without recursing, eg for Dictionary and when a cycle is detected)
struct DummyDecoder: Decoder {
    let decodingType: Any.Type
    public let codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    init(_ type: Any.Type) { decodingType = type }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        return KeyedDecodingContainer(DummyKeyedDecodingContainer<Key>(self))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return DummyUnkeyedDecodingContainer(self)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return DummySingleValueDecodingContainer(self)
    }

}
struct DummyKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let decoder: DummyDecoder
    let codingPath: [CodingKey] = []
    let allKeys: [Key] = []

    init(_ decoder: DummyDecoder) { self.decoder = decoder }

    func contains(_ key: Key) -> Bool { return false }

    func dummy<T>(forKey key: Key) -> T? {
        return (decoder.decodingType as? ValidKeyedCodingValueProvider.Type)?.validCodingValue(forKey: key) as? T
    }

    func decodeNil(forKey: Key) throws -> Bool { return true }
    func decode(_ type: Bool.Type, forKey: Key) throws -> Bool     { return dummy(forKey: forKey) ?? false }
    func decode(_ type: Int.Type, forKey: Key) throws -> Int       { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: Int8.Type, forKey: Key) throws -> Int8     { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: Int16.Type, forKey: Key) throws -> Int16   { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: Int32.Type, forKey: Key) throws -> Int32   { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: Int64.Type, forKey: Key) throws -> Int64   { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: UInt.Type, forKey: Key) throws -> UInt     { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: UInt8.Type, forKey: Key) throws -> UInt8   { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: UInt16.Type, forKey: Key) throws -> UInt16 { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: UInt32.Type, forKey: Key) throws -> UInt32 { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: UInt64.Type, forKey: Key) throws -> UInt64 { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: Float.Type, forKey: Key) throws -> Float   { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: Double.Type, forKey: Key) throws -> Double { return dummy(forKey: forKey) ?? 0 }
    func decode(_ type: String.Type, forKey: Key) throws -> String { return dummy(forKey: forKey) ?? "" }
    func decode<T: Decodable>(_ type: T.Type, forKey: Key) throws -> T { return try T(from: DummyDecoder(type)) }
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        return KeyedDecodingContainer(DummyKeyedDecodingContainer<NestedKey>(decoder))
    }
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return DummyUnkeyedDecodingContainer(decoder)
    }
    func superDecoder() throws -> Decoder { return DummyDecoder(decoder.decodingType) }
    func superDecoder(forKey key: Key) throws -> Decoder { return DummyDecoder(decoder.decodingType) }
}
struct DummyUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    let decoder: DummyDecoder
    let codingPath: [CodingKey] = []
    let count: Int? = 0
    let isAtEnd = true
    let currentIndex = 0

    init(_ decoder: DummyDecoder) { self.decoder = decoder }

    func decodeNil() throws -> Bool { return true }
    func decode(_ type: Bool.Type) throws -> Bool     { return false }
    func decode(_ type: Int.Type) throws -> Int       { return 0 }
    func decode(_ type: Int8.Type) throws -> Int8     { return 0 }
    func decode(_ type: Int16.Type) throws -> Int16   { return 0 }
    func decode(_ type: Int32.Type) throws -> Int32   { return 0 }
    func decode(_ type: Int64.Type) throws -> Int64   { return 0 }
    func decode(_ type: UInt.Type) throws -> UInt     { return 0 }
    func decode(_ type: UInt8.Type) throws -> UInt8   { return 0 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return 0 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return 0 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return 0 }
    func decode(_ type: Float.Type) throws -> Float   { return 0 }
    func decode(_ type: Double.Type) throws -> Double { return 0 }
    func decode(_ type: String.Type) throws -> String { return "" }
    func decode<T: Decodable>(_ type: T.Type) throws -> T { return try T(from: DummyDecoder(type)) }
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        return KeyedDecodingContainer(DummyKeyedDecodingContainer<NestedKey>(decoder))
    }
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return DummyUnkeyedDecodingContainer(decoder)
    }
    func superDecoder() throws -> Decoder {
        return DummyDecoder(decoder.decodingType)
    }
}
struct DummySingleValueDecodingContainer: SingleValueDecodingContainer {
    let decoder: DummyDecoder
    let codingPath: [CodingKey] = []

    init(_ decoder: DummyDecoder) { self.decoder = decoder }

    func dummy<T>() -> T? {
        return (decoder.decodingType as? ValidSingleCodingValueProvider.Type)?.validCodingValue() as? T
    }

    func decodeNil() -> Bool { return true }
    func decode(_ type: Bool.Type) throws -> Bool     { return dummy() ?? false }
    func decode(_ type: Int.Type) throws -> Int       { return dummy() ?? 0 }
    func decode(_ type: Int8.Type) throws -> Int8     { return dummy() ?? 0 }
    func decode(_ type: Int16.Type) throws -> Int16   { return dummy() ?? 0 }
    func decode(_ type: Int32.Type) throws -> Int32   { return dummy() ?? 0 }
    func decode(_ type: Int64.Type) throws -> Int64   { return dummy() ?? 0 }
    func decode(_ type: UInt.Type) throws -> UInt     { return dummy() ?? 0 }
    func decode(_ type: UInt8.Type) throws -> UInt8   { return dummy() ?? 0 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return dummy() ?? 0 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return dummy() ?? 0 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return dummy() ?? 0 }
    func decode(_ type: Float.Type) throws -> Float   { return dummy() ?? 0 }
    func decode(_ type: Double.Type) throws -> Double { return dummy() ?? 0 }
    func decode(_ type: String.Type) throws -> String { return dummy() ?? "" }
    func decode<T: Decodable>(_ type: T.Type) throws -> T { return try T(from: DummyDecoder(type)) }
}

/// `TypeDecoder` allows you to decode a Swift type by using `TypeDecoder.decode()` and passing the type to
/// be decoded.
public struct TypeDecoder {
    fileprivate static func decodeInternal(_ type: Decodable.Type, typePath: [Any.Type]) throws -> TypeInfo {
        let internalDecoder = try InternalTypeDecoder(type, typePath: typePath)
        do {
            _ = try type.init(from: internalDecoder)
            let typeInfo = internalDecoder.typeInfo
            return typeInfo
        } catch let error as DecodingError {
            // Customize the error, informing the user of validation requirements if appropriate.
            // Note, we only attempt to customize a `DecodingError` here, which occurs if decoding
            // of the top-level type fails directly. A `DecodingError` occurring during decoding
            // of a nested type will already have been customized and thrown as a `TypeDecodingError`.
            throw TypeDecodingError.decodingError(decoding: type, underlyingError: error)
        }
    }

    /// Returns a `TypeInfo` enum which describes the type passed in.
    ///
    /// ### Usage Example: ###
    /// ```swift
    /// struct StructureType: Decodable {
    ///   let aString: String
    /// }
    ///
    /// let structureTypeInfo = try TypeDecoder.decode(StructureType.self)
    /// ```
    public static func decode(_ type: Decodable.Type) throws -> TypeInfo {
        return try decodeInternal(type, typePath: [])
    }
}
