<p align="center">
    <a href="http://kitura.dev/">
        <img src="https://raw.githubusercontent.com/Kitura/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>

<p align="center">
    <a href="https://kitura.github.io/TypeDecoder/index.html">
    <img src="https://img.shields.io/badge/apidoc-TypeDecoder-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/Kitura/TypeDecoder">
    <img src="https://travis-ci.org/Kitura/TypeDecoder.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# TypeDecoder

TypeDecoder is a Swift library to allow the inspection of Swift language native and complex types. It was initially written for use within the [Kitura](http://kitura.dev) project but can easily be used for a wide range of projects where the dynamic inspection of types is required.

## Swift version
The latest version of the TypeDecoder requires **Swift 4.0** or newer. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Usage

### Add dependencies

Add `TypeDecoder` to the dependencies within your application's `Package.swift` file. Substitute `"x.x.x"` with the latest `TypeDecoder` [release](https://github.com/Kitura/TypeDecoder/releases).

```swift
.package(url: "https://github.com/Kitura/TypeDecoder.git", from: "x.x.x")
```
Add `TypeDecoder` to your target's dependencies:

```Swift
.target(name: "example", dependencies: ["TypeDecoder"]),
```

### Using the TypeDecoder

`TypeDecoder.decode()` returns a `TypeInfo` enum which describes the type passed to `decode()`. The `TypeInfo` enum values are:

* **.single(Any.Type, Any.Type)** - A basic type, for example String.
* **.keyed(Any.Type, [String: TypeInfo])** - A keyed container type, for example a struct or class.
* **.dynamicKeyed(Any.Type, key: TypeInfo, value: TypeInfo)** - A dynamically keyed container type; a Dictionary.
* **.unkeyed(Any.Type, TypeInfo)** - An unkeyed container type, for example an Array or Set.
* **.optional(TypeInfo)** - An optional container type.
* **.cyclic(Any.Type)** - A type that refers back to its own declaration, for example an Array field in a struct containing the same type as the struct.
* **.opaque(Any.Type)** - A type that cannot be decoded.

For each of these enum values, the first parameter is **always** the original type passed to the `TypeDecoder` for decoding.

### Example

To use the TypeDecoder you need to declare a type which conforms to the `Decodable` protocol, such as the struct `StructureType` below.

```swift
import TypeDecoder

struct StructureType: Decodable {
    let aString: String
}
```

You then call `TypeDecoder.decode()` passing the type to be decoded. If you print the contents of the returned `TypeInfo` enum you can see it describes the type passed to `decode()`.

```swift
let structureTypeInfo = try TypeDecoder.decode(StructureType.self)
print("\(structureTypeInfo)")
```

Printing the structureTypeInfo will output:
```
StructureType{
  aString: String
}
```

You can then use `.keyed(Any.Type, [String: TypeInfo])` to obtain a Dictionary of all the fields contained in the keyed structure, this allows you to retrieve each field's `TypeInfo` by name.

In the case below, the type of field "aString" is a basic type, so you can use `.single(Any.Type, Any.Type)`. The appropriate enum value to call will vary depending on the field type, see the full implementation below for how to decode more complex types.

```swift
if case .keyed(_, let dict) = structureTypeInfo {

  print("\nThe Dictionary returned from decoding StructureType contains:\n\(dict)")

  /// Fields that are not containers will be .single
  if let theTypeInfo = dict["aString"] {
    if case .single(_) = theTypeInfo {
      print("aString is type \(theTypeInfo)")
    }
  }
}
```

You will see the following output:
```
The Dictionary returned from decoding StructureType contains:
OrderedDictionary<String, TypeInfo>(keys: ["aString"], values: ["aString": String], iteratorCount: 1)
aString is type String
```

## Full implementation

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
            /// .keyed TypeInfo contains a Dictionary<String, TypeInfo> of all fields contained in
            /// the keyed structure, so each field's TypeInfo can be retrieved by name.
            print("\nThe Dictionary returned from decoding StructType contains:\n\(dict)")
            print("\nEach field can be individually inspected:")

            /// Fields that are not containers will be .single
            if let theTypeInfo = dict["myString"] {
                if case .single(_) = theTypeInfo {
                    print("myString is type \(theTypeInfo)")
                }
            }

            /// .dynamicKeyed fields are Dictionary types
            if let theTypeInfo = dict["myDict"] {
                if case .dynamicKeyed(_, let keyTypeInfo, let valueTypeInfo) = theTypeInfo {
                    print("myDict is type Dictionary<\(keyTypeInfo), \(valueTypeInfo)>")
                }
            }

            /// .unkeyed fields are Array or Set types
            if let theTypeInfo = dict["myArray"] {
                if case .unkeyed(_, let theTypeInfo) = theTypeInfo {
                    print("myArray contains type \(theTypeInfo)")
                }
            }

            /// .optional field types
            if let theTypeInfo = dict["myOptional"] {
                if case .optional(let theTypeInfo) = theTypeInfo {
                    print("myOptional is type \(theTypeInfo)")
                }
            }

            /// .cyclic fields are embedded inside .unkeyed (Array or Set) types  
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

## API documentation

For more information visit our [API reference](http://kitura.github.io/TypeDecoder/).

## Community

We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/Kitura/TypeDecoder/blob/master/LICENSE.txt).
