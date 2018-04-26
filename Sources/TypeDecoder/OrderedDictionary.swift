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
public struct OrderedDictionary<K: Hashable, V>: Sequence, IteratorProtocol {
    private var keys: Array<K> = []
    private var values: Dictionary<K, V> = [:]
    private var iteratorCount = 0

    public init() {}

    public var count: Int {
        get {
            return self.keys.count
        }
    }

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

    public var description: String {
        var result = ""
        for (k, v) in self {
            result += "\(k): \(v)\n"
        }
        return result
    }

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
