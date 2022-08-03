//
//  File.swift
//  
//
//  Created by Jonas Zell on 03.08.22.
//

import Foundation

public func clamp<T : Comparable>(_ value: T, lower: T, upper: T) -> T {
    return max(lower, min(value, upper))
}

public extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }
    
    var intValue: Int {
        return NSDecimalNumber(decimal:self).intValue
    }
    
    func rounded(_ scale: Int = 0, _ mode: NSDecimalNumber.RoundingMode = .bankers) -> Decimal {
        var this = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &this, scale, mode)
        
        return rounded
    }
}

public extension BinaryFloatingPoint {
    // https://math.stackexchange.com/questions/106700/incremental-averaging
    static func updateRunningMean(meanSoFar: Self, valueCountSoFar: Int, newValue: Self) -> Self {
        meanSoFar + ((newValue - meanSoFar) / (Self(valueCountSoFar) + 1))
    }
    
    mutating func roundUp(toMultipleOf multiple: Self) {
        let remainder = self.truncatingRemainder(dividingBy: multiple)
        if remainder.isZero {
            return
        }
        
        self += (multiple - remainder)
    }
    
    func roundedUp(toMultipleOf multiple: Self) -> Self {
        var copy = self
        copy.roundUp(toMultipleOf: multiple)
        
        return copy
    }
    
    mutating func roundDown(toMultipleOf multiple: Self) {
        let remainder = self.truncatingRemainder(dividingBy: multiple)
        self -= remainder
    }
    
    func roundedDown(toMultipleOf multiple: Self) -> Self {
        var copy = self
        copy.roundDown(toMultipleOf: multiple)
        
        return copy
    }
    
    /// Round a number to a given number of decimal places.
    func rounded(toDecimalPlaces decimalPlaces: Int) -> Self {
        let pow = Self(10 ** decimalPlaces)
        let rounded = Int(self * pow)
        
        return Self(rounded) / pow
    }
}

public extension SignedInteger {
    mutating func roundUp(toMultipleOf multiple: Self) {
        let remainder = self % multiple
        if remainder == 0 {
            return
        }
        
        self += (multiple - remainder)
    }
    
    func roundedUp(toMultipleOf multiple: Self) -> Self {
        var copy = self
        copy.roundUp(toMultipleOf: multiple)
        
        return copy
    }
    
    mutating func roundDown(toMultipleOf multiple: Self) {
        let remainder = self % multiple
        self -= remainder
    }
    
    func roundedDown(toMultipleOf multiple: Self) -> Self {
        var copy = self
        copy.roundDown(toMultipleOf: multiple)
        
        return copy
    }
}

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ** : PowerPrecedence

func ** (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}

func ** (radix: Decimal, power: Int) -> Decimal {
    if power == 0 {
        return 1
    }
    
    if power == 1 {
        return radix
    }
    
    var result = radix
    for _ in 1..<power {
        result *= radix
    }
    
    return result
}
