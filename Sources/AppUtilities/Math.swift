
import Foundation
import SwiftUI

extension BinaryFloatingPoint {
    /// Utility constant to transform between radians and degrees.
    static var rad2deg: Self { 180 / Self.pi }
    
    /// Utility constant to transform between degrees and radians.
    static var deg2rad: Self { Self.pi / 180 }
}

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

public func ** (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}

public func ** (radix: Decimal, power: Int) -> Decimal {
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

/// - returns: A point on a circle of radius `radius` rotating `angle` degrees clockwise around the edge.
public func pointOnCircle(radius: CGFloat, angle: Angle) -> CGPoint {
    // https://math.stackexchange.com/a/260115
    CGPoint(x: radius * Darwin.sin(angle.radians), y: radius * Darwin.cos(angle.radians))
}

// MARK: Statistics

public func linearRegression(_ xs: [Double], _ ys: [Double]) -> (Double) -> Double {
    assert(xs.count != 0)
    assert(xs.count == ys.count)
    
    let mean_xs = xs.mean!
    let mean_ys = ys.mean!
    
    var product = [Double]()
    for i in 0..<xs.count {
        product.append(ys[i] * xs[i])
    }
    
    let correlation = product.mean!
    let autocorrelation = xs.map { $0*$0 }.mean!
    
    let sum1 = correlation - mean_xs * mean_ys
    let sum2 = autocorrelation - pow(mean_xs, 2)
    let slope = sum1 / sum2
    let intercept = mean_ys - slope * mean_xs
    
    return { x in intercept + slope * x }
}
