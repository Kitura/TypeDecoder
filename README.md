# TypeDecoder

## Summary

TypeDecoder is a Swift library to allow the inspection of Swift language native and complex types. It was initially written for use within the [Kitura](http://kitura.io) project but can easily be used for a wide range of projects where the dynamic inspection of types is required. 

## Table of Contents
* [Summary](#summary)
* [Usage](#usage)

## Swift version
The latest version of the TypeDecoder requires **Swift 4.0** or newer. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Usage

`TypeDecoder.decode()` returns a TypeInfo enum which describes the type passed to `decode()`. The TypeInfo enum values are:

* **.single(Any.Type, Any.Type)** - A basic type.
* **.keyed(Any.Type, [String: TypeInfo])** - A keyed container type, for example a struct or class.
* **.dynamicKeyed(Any.Type, key: TypeInfo, value: TypeInfo)** - A dynamically keyed container type; a Dictionary.
* **.unkeyed(Any.Type, TypeInfo)** - An unkeyed container type, for example an Array or Set.
* **.optional(TypeInfo)** - An optional container type.
* **.cyclic(Any.Type)** - A type that refers back to its own declaration, for example an Array field in a struct containing the same type as the struct.
* **.opaque(Any.Type)** - A type that cannot be decoded.

For each of these enum values, the first parameter is **always** the original type passed to the TypeDecoder for decoding.

```swift
/// Building and running this example shows how to decode a Swift data structure.
///
/// You should expect to see the following output:
///
/// Print the returned TypeInfo and you get this:
/// StructType{
///   myString: String,
///   myOptional: Float?,
///   myCyclic: [StructType{<cyclic>}],
///   myDict: [String:Bool],
///   myArray: [Int8]
/// }
///
/// The Dictionary returned from decoding StructType contains:
/// ["myString": String, "myOptional": Float?, "myCyclic": [StructType{<cyclic>}], "myDict": [String:Bool], "myArray": [Int8]]
///
/// Each field can be individually inspected:
/// myString is type String
/// myDict is type Dictionary<String, Bool>
/// myArray contains type Int8
/// myOptional is type Float
///
/// Cyclics are harder to deal with as they're buried inside an Array type:
/// myCyclic is type StructType

import TypeDecoder

struct StructType: Decodable {
    let myString: String
    let myDict: Dictionary<String, Bool>
    let myArray: [Int8]
    let myOptional: Float?
    let myCyclic: [StructType]
}

func main() {
    do {
        let structTypeInfo = try TypeDecoder.decode(StructType.self)
        /// Print the returned TypeInfo and you get this:
        ///
        /// StructType{
        ///   myString: String,
        ///   myDict: [String:Bool],
        ///   myArray: [Int8],
        ///   myOptional: Float?,
        ///   myCyclic: [StructType{<cyclic>}]
        /// }
        print("Print the returned TypeInfo and you get this:\n\(structTypeInfo)")

        if case .keyed(_, let dict) = structTypeInfo {
            /// .keyed TypeInfo conatins a Dictionary<String, TypeInfo> of all fields contained in
            /// the keyed structure. So each field's TypeInfo can be retrieved by name.
            print("\nThe Dictionary returned from decoding StructType contains:\n\(dict)")
            print("\nEach field can be individually inspected:")

            /// Fields that are not containers will be .single
            if let theTypeInfo = dict["myString"] {
                if case .single(_) = theTypeInfo {
                    print("myString is type \(theTypeInfo)")
                }
            }

            /// .dynamicKeyed fields are Dictionary
            if let theTypeInfo = dict["myDict"] {
                if case .dynamicKeyed(_, let keyTypeInfo, let valueTypeInfo) = theTypeInfo {
                    print("myDict is type Dictionary<\(keyTypeInfo), \(valueTypeInfo)>")
                }
            }

            /// .unkeyed fields are Array or Set
            if let theTypeInfo = dict["myArray"] {
                if case .unkeyed(_, let theTypeInfo) = theTypeInfo {
                    print("myArray contains type \(theTypeInfo)")
                }
            }

            /// .optional field
            if let theTypeInfo = dict["myOptional"] {
                if case .optional(let theTypeInfo) = theTypeInfo {
                    print("myOptional is type \(theTypeInfo)")
                }
            }

            /// .cyclic fields are embedded inside .unkeyed (Array or Set)  
            if let theTypeInfo = dict["myCyclic"] {
                print("\nCyclics are harder to deal with as they're buried inside an Array type:")
                if case .unkeyed(_, let theTypeInfo) = theTypeInfo {
                    if case .cyclic(let theTypeInfo) = theTypeInfo {
                        print("myCyclic is type \(theTypeInfo)")
                    }
                }
            }
        }
    } catch let error {
        print(error)
    }
}

main()
```

## Compatibility with types that perform validation

The `TypeDecoder` works by using the `Codable` framework to simulate the decoding of a type. The `init(from: Decoder)` initializer is invoked for the type (and any nested types), in order to discover its structure. To create an instance without a serialized representation, the decoder provides dummy values for each field.

However, there are cases a type may need to perform validation of these values during initialization. TypeDecoder provides a mechanism for providing acceptable values during decoding through the `ValidSingleCodingValueProvider` and `ValidKeyedCodingValueProvider` protocols.

### ValidSingleCodingValueProvider

Below is an example of an `enum` with a raw value of `String`. Swift can synthesize Codable conformance for such a type, producing an `init(from: Decoder)` that requires a valid String matching one of the enum cases. Here is how you can extend such a type to be compatible with TypeDecoder:
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

### ValidKeyedCodingValueProvider

An example of a structured type, where one of the fields is validated, and an extension that enables it to be handled by the TypeDecoder:
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
extension YoungAdult: DummyKeyedCodingValueProvider {
    public static func dummyCodingValue(forKey key: CodingKey) -> Any? {
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

An example, implemented in TypeDecoder, of extending a Foundation type that requires validation, and that uses numeric CodingKeys:
```swift
extension URL: ValidKeyedCodingValueProvider {
    public static func validCodingValue(forKey key: CodingKey) -> Any? {
        switch key.intValue {
        case 1?: return "http://example.com/"
        default: return nil
        }
    }
}
```
