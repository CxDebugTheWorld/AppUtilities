//
//  File.swift
//  
//
//  Created by Jonas Zell on 03.08.22.
//

import Foundation

// MARK: String extensions

// https://stackoverflow.com/questions/2590677/how-do-i-combine-hash-values-in-c0x
public func combineHashes(_ lhs: inout Int, _ rhs: Int) {
    lhs ^= rhs &+ 0x9e3779b9 &+ (lhs &<< 6) &+ (lhs &>> 2)
}

public protocol StableHashable: Hashable {
    /// The stable hash value, i.e. one that is the same across launches.
    var stableHash: Int { get }
}

public extension StableHashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.stableHash)
    }
}

extension Int: StableHashable {
    public var stableHash: Int {
        self
    }
}

extension String: StableHashable {
    public var stableHash: Int {
        self.djb2Hash
    }
}

extension Double: StableHashable {
    public var stableHash: Int {
        Int(truncatingIfNeeded: self.bitPattern)
    }
}

extension Decimal: StableHashable {
    public var stableHash: Int {
        doubleValue.stableHash
    }
}

extension Bool: StableHashable {
    public var stableHash: Int {
        self ? 1 : 0
    }
}

extension Optional: StableHashable where Wrapped: StableHashable {
    public var stableHash: Int {
        switch self {
        case .none:
            return 0
        case .some(let wrapped):
            return wrapped.stableHash
        }
    }
}

extension Array: StableHashable where Element: StableHashable {
    public var stableHash: Int {
        var hash = 0
        for e in self {
            combineHashes(&hash, e.stableHash)
        }
        
        return hash
    }
}

// MARK: String extensions

public extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    // http://www.cse.yorku.ca/~oz/hash.html
    var djb2Hash: Int {
        var hash = 5381
        for character in self {
            guard let ascii = character.asciiValue else {
                continue
            }
            
            let c = Int(ascii)
            hash = ((hash &<< 5) &+ hash) &+ c
        }
        
        return hash
    }
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

func randomString(length: Int, using rng: inout ARC4RandomNumberGenerator) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement(using: &rng)! })
}

extension String: Error {}

public func NSLocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

// MARK: Array extensions

public extension Array {
    func tryGet(_ index: Int) -> Element? {
        index < self.count ? self[index] : nil
    }
}

public extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    func chunked(into size: Int, padWith: Element) -> [[Element]] {
        var chunks = stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
        
        if chunks.count > 0 && chunks.last!.count != size {
            var last = chunks[chunks.count - 1]
            while last.count < size {
                last.append(padWith)
            }
            
            chunks[chunks.count - 1] = last
        }
        
        return chunks
    }
    
    func appending(contentsOf elements: [Element]) -> [Element] {
        var copy = self
        copy.append(contentsOf: elements)
        
        return copy
    }
}

extension Array where Element: Equatable {
    public var unique: [Element] {
        var newArray = [Element]()
        for el in self {
            if newArray.firstIndex(of: el) != nil {
                continue
            }
            
            newArray.append(el)
        }
        
        return newArray
    }
}

public extension Array {
    func unique<T: Hashable>(by getUniqueProperty: (Element) -> T) -> [Element] {
        var newArray = [Element]()
        var set = Set<T>()
        
        for el in self {
            guard set.insert(getUniqueProperty(el)).inserted else {
                continue
            }
            
            newArray.append(el)
        }
        
        return newArray
    }
}

extension Array where Element: FloatingPoint {
    /// The mean of the values in this array.
    public var mean: Element? {
        guard self.count > 0 else {
            return nil
        }
        
        return self.reduce(0) { $0 + $1 } / Element(self.count)
    }
}

public extension Array {
    /// Choose a random element weighted by some property.
    func randomElement(using rng: inout ARC4RandomNumberGenerator, weightedBy keypath: KeyPath<Element, Int>) -> Element? {
        guard count > 0 else {
            return nil
        }
        
        let total = self.reduce(0) { $0 + $1[keyPath: keypath] }
        return randomElement(using: &rng, weightedBy: keypath, precomputedTotal: total)
    }
    
    /// Choose a random element weighted by some property.
    func randomElements(using rng: inout ARC4RandomNumberGenerator, weightedBy keypath: KeyPath<Element, Int>, count: Int) -> [Element]? {
        guard self.count > 0 else {
            return nil
        }
        
        let total = self.reduce(0) { $0 + $1[keyPath: keypath] }
        var result = [Element]()
        
        for _ in 0..<count {
            guard let next = randomElement(using: &rng, weightedBy: keypath, precomputedTotal: total) else {
                return nil
            }
            
            result.append(next)
        }
        
        return result
    }
    
    /// Choose a random element weighted by some property.
    func randomElement(using rng: inout ARC4RandomNumberGenerator, weightedBy keypath: KeyPath<Element, Int>, precomputedTotal: Int) -> Element? {
        guard count > 0 && precomputedTotal > 0 else {
            return nil
        }
        
        let rnd = rng.random(in: 0..<precomputedTotal)
        
        var sum = 0
        for el in self {
            sum += el[keyPath: keypath]
            if rnd < sum {
                return el
            }
        }
        
        return nil
    }
}

// MARK: Set extensions

public extension Set {
    /// Insert all elements of the given collection into this set.
    @discardableResult mutating func insert<S: Sequence>(contentsOf sequence: S) -> Int
    where S.Element == Element
    {
        var newValues = 0
        for element in sequence {
            if self.insert(element).inserted {
                newValues += 1
            }
        }
        
        return newValues
    }
}

// MARK: Dictionary extensions

public extension Dictionary where Value: AdditiveArithmetic {
    /// Add the values in the given dictionary to the values of another dictionary with the same keys.
    mutating func add(valuesOf other: Self) {
        let keys = other.keys.map { $0 }
        for key in keys {
            guard let otherValue = other[key] else {
                continue
            }
            
            if let value = self[key] {
                self[key] = value + otherValue
            }
            else {
                self[key] = otherValue
            }
        }
    }
    
    /// Group the items of this dictionary by generating a new key for each item.
    func grouped<NewKey>(by transformKey: (Key) -> NewKey) -> [NewKey: Value]
    where NewKey: Hashable
    {
        grouped(by: transformKey) { $0 + $1 }
    }
}

public extension Dictionary {
    /// Group the items of this dictionary by generating a new key for each item.
    func grouped<NewKey>(by transformKey: (Key) -> NewKey, combineValues: (Value, Value) -> Value) -> [NewKey: Value]
    where NewKey: Hashable
    {
        var dict = [NewKey: Value]()
        for (key, value) in self {
            let newKey = transformKey(key)
            
            if let existingValue = dict[newKey] {
                dict[newKey] = combineValues(existingValue, value)
            }
            else {
                dict[newKey] = value
            }
        }
        
        return dict
    }
}

