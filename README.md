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
