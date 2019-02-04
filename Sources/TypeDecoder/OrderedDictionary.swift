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

///
public struct OrderedDictionary<K: Hashable, V> {
    private var keys: Array<K> = []
    private var values: Dictionary<K, V> = [:]
    private var iteratorCount = 0

    /// `OrderedDictionary` constructor.
    public init() {}

    /// Read only property that provides the number of elements in the `OrderedDictionary`.
    public var count: Int {
        get {
            return self.keys.count
        }
    }

    /// Provides a way to add and remove elements from the
    /// `OrderedDictionary`, just like any other `Dictionary`.
    ///
    /// Setting an element to nil will remove it from the `OrderedDictionary`.
    public subscript(key: K) -> V? {
        get {
            return self.values[key]
        }
        set(value) {
            if let new = value {
                let old = self.values.updateValue(new, forKey: key)
                if old == nil {
                    self.keys.append(key)
                }
                self.iteratorCount = self.keys.count
                return
            }
            self.values.removeValue(forKey: key)
            self.keys = self.keys.filter {$0 != key}
            self.iteratorCount = self.keys.count
            return
        }
    }

    /// Return the element value at the numeric index specified.
    public subscript(index: Int) -> V? {
        if self.keys.indices.contains(index) {
            let key = self.keys[index]
            return self.values[key]
        }
        return nil
    }

    /// Read only property that provides a String containing the key:value pairs in the `OrderedDictionary`.
    public var description: String {
        var result = ""
        for (k, v) in self {
            result += "\(k): \(v)\n"
        }
        return result
    }

}

extension OrderedDictionary: Sequence, IteratorProtocol {
    /// Method to allow iteration over the contents of the
    /// `OrderedDictionary`. This method ensures that items are read in the same
    /// sequence as they were added.
    public mutating func next() -> (K, V)? {
        if self.iteratorCount == 0 {
            return nil
        } else {
            defer { self.iteratorCount -= 1 }
            let theKey = self.keys[self.keys.count - self.iteratorCount]
            let theValue = self.values[theKey]
            if let unwrappedValue = theValue {
                return(theKey, unwrappedValue)
            }
            return nil
        }
    }
}
