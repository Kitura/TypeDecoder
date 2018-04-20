# TypeDecoder

## Summary

TypeDecoder is a Swift library to allow the inspection of Swift language native and complex types. It was initially written for use within the [Kitura](http://kitura.io) project but can easily be used for a wide range of projects where the dynamic inspection of types is required. 

## Table of Contents
* [Summary](#summary)
* [Usage](#usage)

## Usage

TypeDecoder.decode() returns a TypeInfo enum which describes the type passed to decode(). The TypeInfo enum values are:

* .keyed(Any.Type, [String: TypeInfo]) - A keyed container type, for example a struct or class.
* .dynamicKeyed(Any.Type, key: TypeInfo, value: TypeInfo) - A dynamically keyed container type; a Dictionary.
* .unkeyed(Any.Type, TypeInfo) - An unkeyed container type, for example an Array, Tuple or Set.
* .optional(TypeInfo) - An optional container type.
* .single(Any.Type, Any.Type) - A basic type.
* .cyclic(Any.Type) - A type that refers back to its own declaration, for example an Array field in a struct containing the same type as the struct.
* .opaque(Any.Type) - A type that cannot be decoded.

For each of these enum values, the first parameter is **always** the original type passed to the TypeDecoder for decoding.

```swift
import TypeDecoder                                                                                                       
                                                                                                                         
struct StructType: Decodable {                                                                                           
    let myString: String                                                                                                 
    let myBool: Bool                                                                                                     
    let myDict: Dictionary<String, Int>                                                                                  
    let myArray: [Int8]                                                                                                  
    let myOptional: Float?                                                                                                 
    let myCyclic: [StructType]                                                                                           
}                                                                                                                        
                                                                                                                         
func main() {                                                                                                            
    do {                                                                                                                 
        let structType = try TypeDecoder.decode(StructType.self)                                                         
                                                                                                                         
        if case .keyed(_, let dict) = structType {                                                                       
            print("StructType contains:\n\(dict)")                                                                       
            print("\nEach field can be individually inspected:")                                                         
            if let theTypeInfo = dict["myString"] {                                                                      
                print("myString is type \(theTypeInfo)")                                                                 
            }                                                                                                            
            if let theTypeInfo = dict["myBool"] {                                                                        
                print("myBool is type \(theTypeInfo)")                                                                   
            }                                                                                                            
            if let theTypeInfo = dict["myDict"] {                                                                        
                if case .dynamicKeyed(_, let keyTypeInfo, let valueTypeInfo) = theTypeInfo {                             
                    print("myDict is type Dictionary<\(keyTypeInfo), \(valueTypeInfo)>")                                 
                }                                                                                                        
            }                                                                                                            
            if let theTypeInfo = dict["myArray"] {                                                                       
                if case .unkeyed(_, let theTypeInfo) = theTypeInfo {                                                     
                    print("myArray contains type \(theTypeInfo)")                                                        
                }                                                                                                        
            }                                                                                                            
            if let theTypeInfo = dict["myOptional"] {                                                                    
                if case .optional(let theTypeInfo) = theTypeInfo {                                                       
                    print("myOptional is type \(theTypeInfo)")                                                           
                }                                                                                                        
            }                                                                                                            
            if let theTypeInfo = dict["myCyclic"] {                                                                      
                print("\nCyclics are harder to deal with as they're buried inside an Array type")                        
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
                                                                                                                         
    do {                                                                                                                 
        let boolTypeInfo = try TypeDecoder.decode(Bool.self)                                                             
        if case .single(_) = boolTypeInfo {                                                                              
            print("\nThis single type is a \(boolTypeInfo)")                                                             
        }                                                                                                                
    } catch let error {                                                                                                  
        print(error)                                                                                                     
    }                                                                                                                    
}
```
