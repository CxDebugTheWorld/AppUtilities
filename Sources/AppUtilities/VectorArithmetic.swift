
import SwiftUI
import enum Accelerate.vDSP

public struct AnimatableVector: VectorArithmetic {
    public static var zero = AnimatableVector(values: [0.0])
    
    public static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        var copy = lhs
        copy += rhs
        return copy
    }
    
    public static func += (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        let count = min(lhs.values.count, rhs.values.count)
        vDSP.add(lhs.values[0..<count], rhs.values[0..<count], result: &lhs.values[0..<count])
    }
    
    public static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        var copy = lhs
        copy -= rhs
        return copy
    }
    
    public static func -= (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        let count = min(lhs.values.count, rhs.values.count)
        vDSP.subtract(lhs.values[0..<count], rhs.values[0..<count], result: &lhs.values[0..<count])
    }
    
    public var values: [Double]
    
    public mutating func scale(by rhs: Double) {
        values = vDSP.multiply(rhs, values)
    }
    
    public var magnitudeSquared: Double {
        vDSP.sum(vDSP.multiply(values, values))
    }
}

public extension CGRect {
    /// The center point of the rectangle.
    var center: CGPoint {
        CGPoint(x: origin.x + (size.width * 0.5), y: origin.y + (size.height * 0.5))
    }
    
    /// The surface area of the rectangle.
    var area: CGFloat {
        width * height
    }
    
    /// A random point in this rectangle.
    func randomPoint(using rng: inout ARC4RandomNumberGenerator) -> CGPoint {
        let x = CGFloat.random(in: 0..<self.width)
        let y = CGFloat.random(in: 0..<self.height)
        
        return .init(x: x, y: y)
    }
    
    /// A random point on one of the edges.
    func randomPointOnEdge(using rng: inout ARC4RandomNumberGenerator) -> CGPoint {
        let x: CGFloat, y: CGFloat
        
        let edge = Edge.allCases.randomElement(using: &rng)!
        switch edge {
        case .top:
            x = CGFloat.random(in: 0..<self.width)
            y = 0
        case .leading:
            x = 0
            y = CGFloat.random(in: 0..<self.height)
        case .bottom:
            x = CGFloat.random(in: 0..<self.width)
            y = height
        case .trailing:
            x = width
            y = CGFloat.random(in: 0..<self.height)
        }
        
        return .init(x: x, y: y)
    }
    
    /// Whether or not the given line intersects this rectangle.
    func intersectsLine(start: CGPoint, end: CGPoint) -> CGPoint? {
        var (pt, intersects) = getIntersectionPoint(topLeft, topRight, start, end)
        if intersects {
            return pt
        }
        
        (pt, intersects) = getIntersectionPoint(topRight, bottomRight, start, end)
        if intersects {
            return pt
        }
        
        (pt, intersects) = getIntersectionPoint(bottomRight, bottomLeft, start, end)
        if intersects {
            return pt
        }
        
        (pt, intersects) = getIntersectionPoint(bottomLeft, topLeft, start, end)
        if intersects {
            return pt
        }
        
        return nil
    }
    
    /// Scale the rect by the given dimensions.
    func scaled(width: CGFloat, height: CGFloat) -> CGRect {
        .init(x: minX * width, y: minY * height,
              width: self.width * width, height: self.height * height)
    }
    
    /// Scale the rect by the given dimensions.
    func scaled(by size: CGSize) -> CGRect {
        scaled(width: size.width, height: size.height)
    }
    
    /// Scale the rect by the given dimensions.
    mutating func scale(width: CGFloat, height: CGFloat) {
        self = self.scaled(width: width, height: height)
    }
    
    /// Scale the rect by the given dimensions.
    mutating func scale(by size: CGSize) {
        self = self.scaled(by: size)
    }
    
    /// The top left corner of this rectangle.
    var topLeft: CGPoint { .init(x: minX, y: minY) }
    
    /// The top right corner of this rectangle.
    var topRight: CGPoint { .init(x: maxX, y: minY) }
    
    /// The bottom left corner of this rectangle.
    var bottomLeft: CGPoint { .init(x: minX, y: maxY) }
    
    /// The bottom right corner of this rectangle.
    var bottomRight: CGPoint { .init(x: maxX, y: maxY) }
    
    /// Expand a bounding box rectangle to contain the given point.
    func expanded(toContain point: CGPoint) -> CGRect {
        let minX = min(self.minX, point.x)
        let minY = min(self.minY, point.y)
        let maxX = max(self.maxX, point.x)
        let maxY = max(self.maxY, point.y)
        
        return .init(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.minX)
        hasher.combine(self.minY)
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
}

extension CGPoint: VectorArithmetic {
    public mutating func scale(by rhs: Double) {
        x = x * CGFloat(rhs)
        y = y * CGFloat(rhs)
    }
    
    /// Project this unit point into a rectangle.
    public func projectUnitPoint(onto rect: CGRect) -> CGPoint {
        CGPoint(x: self.x * rect.width, y: self.y * rect.height)
    }
    
    public var magnitudeSquared: Double {
        Double((x*x) + (y*y))
    }
    
    // Vector addition
    public static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    // Vector subtraction
    public static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    // Vector addition assignment
    public static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }
    
    // Vector subtraction assignment
    public static func -= (left: inout CGPoint, right: CGPoint) {
        left = left - right
    }
    
    // Vector negation
    public static prefix func - (vector: CGPoint) -> CGPoint {
        return CGPoint(x: -vector.x, y: -vector.y)
    }
}

extension CGSize: VectorArithmetic {
    public mutating func scale(by rhs: Double) {
        width = width * CGFloat(rhs)
        height = height * CGFloat(rhs)
    }
    
    public var magnitudeSquared: Double {
        Double((width*width) + (height*height))
    }
    
    // Vector addition
    public static func + (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width + right.width, height: left.height + right.height)
    }
    
    // Vector subtraction
    public static func - (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width - right.width, height: left.height - right.height)
    }
    
    // Vector addition assignment
    public static func += (left: inout CGSize, right: CGSize) {
        left = left + right
    }
    
    // Vector subtraction assignment
    public static func -= (left: inout CGSize, right: CGSize) {
        left = left - right
    }
    
    // Vector negation
    public static prefix func - (vector: CGSize) -> CGSize {
        return CGSize(width: -vector.width, height: -vector.height)
    }
}

public extension CGSize {
    // Scalar-vector multiplication
    static func * (left: CGFloat, right: CGSize) -> CGSize {
        return CGSize(width: right.width * left, height: right.height * left)
    }
    
    static func * (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width * right, height: left.height * right)
    }
    
    // Vector-scalar division
    static func / (left: CGSize, right: CGFloat) -> CGSize {
        guard right != 0 else { fatalError("Division by zero") }
        return CGSize(width: left.width / right, height: left.height / right)
    }
    
    // Vector-scalar division assignment
    static func /= (left: inout CGSize, right: CGFloat) -> CGSize {
        guard right != 0 else { fatalError("Division by zero") }
        return CGSize(width: left.width / right, height: left.height / right)
    }
    
    // Scalar-vector multiplication assignment
    static func *= (left: inout CGSize, right: CGFloat) {
        left = left * right
    }
}

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
}

public extension CGPoint {
    // Scalar-vector multiplication
    static func * (left: CGFloat, right: CGPoint) -> CGPoint {
        return CGPoint(x: right.x * left, y: right.y * left)
    }
    
    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }
    
    // Vector-scalar division
    static func / (left: CGPoint, right: CGFloat) -> CGPoint {
        guard right != 0 else { fatalError("Division by zero") }
        return CGPoint(x: left.x / right, y: left.y / right)
    }
    
    // Vector-scalar division assignment
    static func /= (left: inout CGPoint, right: CGFloat) -> CGPoint {
        guard right != 0 else { fatalError("Division by zero") }
        return CGPoint(x: left.x / right, y: left.y / right)
    }
    
    // Scalar-vector multiplication assignment
    static func *= (left: inout CGPoint, right: CGFloat) {
        left = left * right
    }
}

public extension CGPoint {
    // Vector magnitude (length)
    var magnitude: CGFloat {
        return sqrt(x*x + y*y)
    }
    
    // Distance between two vectors
    func distance(to vector: CGPoint) -> CGFloat {
        return (self - vector).magnitude
    }
    
    // Vector normalization
    var normalized: CGPoint {
        return CGPoint(x: x / magnitude, y: y / magnitude)
    }
    
    // Dot product of two vectors
    func dot (_ right: CGPoint) -> CGFloat {
        return x * right.x + y * right.y
    }
    
    // Cross product of two vectors.
    func cross(_ right: CGPoint) -> CGFloat {
        return x * right.y - y * right.x
    }
    
    // Angle between two vectors
    // θ = acos(AB)
    func angle(to vector: CGPoint) -> CGFloat {
        return acos(self.normalized.dot(vector.normalized))
    }
    
    // Signed angle between two vectors
    func signedAngle(to vector: CGPoint) -> CGFloat {
        atan2(self.x * vector.y - self.y * vector.x, self.x * vector.x + self.y * vector.y)
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
}

/// Returns the intersection between two line segments, if it exists.
public func getIntersectionPoint(
    _ A1: CGPoint, _ A2: CGPoint,
    _ B1: CGPoint, _ B2: CGPoint
) -> (CGPoint, Bool) {
    let tmp = (B2.x - B1.x) * (A2.y - A1.y) - (B2.y - B1.y) * (A2.x - A1.x)
    if (tmp == 0) {
        return (CGPoint(), false)
    }
    
    let mu = ((A1.x - B1.x) * (A2.y - A1.y) - (A1.y - B1.y) * (A2.x - A1.x)) / tmp
    return (.init(x: B1.x + (B2.x - B1.x) * mu, y: B1.y + (B2.y - B1.y) * mu), true)
}

public enum CircleLineIntersectionResult {
    case NoIntersection
    case Tangent(CGPoint)
    case Secant(CGPoint, CGPoint)
}

/// Returns the intersection between a line and a circle, if it exists.
public func circleLineIntersections(_ p: CGPoint, _ q: CGPoint, radius r: CGFloat, center c: CGPoint)
    -> CircleLineIntersectionResult
{
    let dx = q.x - p.x
    let dy = q.y - p.y
    let A = dx*dx + dy*dy
    let B = 2 * (dx * (p.x - c.x) + dy * (p.y - c.y))
    let C = (p.x - c.x) * (p.x - c.x) + (p.y - c.y) * (p.y - c.y) - r * r;
    
    // Determine discriminant
    let discriminant = B*B - 4*A*C
    
    // discriminant < 0: no intersection
    if A.isZero || discriminant < 0 {
        return .NoIntersection
    }
    
    // discriminant == 0: tangent
    if discriminant.isZero {
        let t = -B / (2*A)
        return .Tangent(CGPoint(x: p.x + t*dx, y: p.y + t*dy))
    }
    
    // discriminant > 0: two intersection points
    let t1 = (-B + sqrt(discriminant)) / (2*A)
    let t2 = (-B - sqrt(discriminant)) / (2*A)
    
    return .Secant(
        CGPoint(x: p.x + t1*dx, y: p.y + t1*dy),
        CGPoint(x: p.x + t2*dx, y: p.y + t2*dy)
    )
}

public struct AnimatableTuple3<A: VectorArithmetic, B: VectorArithmetic, C: VectorArithmetic>: VectorArithmetic {
    public var first: A
    public var second: B
    public var third: C
    
    init(_ first: A, _ second: B, _ third: C) {
        self.first = first
        self.second = second
        self.third = third
    }
    
    public static var zero: Self { .init(.zero, .zero, .zero) }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        var copy = lhs
        copy += rhs
        return copy
    }
    
    public static func += (lhs: inout Self, rhs: Self) {
        lhs.first += rhs.first
        lhs.second += rhs.second
        lhs.third += rhs.third
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        var copy = lhs
        copy -= rhs
        return copy
    }
    
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.first -= rhs.first
        lhs.second -= rhs.second
        lhs.third -= rhs.third
    }
    
    public mutating func scale(by rhs: Double) {
        first.scale(by: rhs)
        second.scale(by: rhs)
        third.scale(by: rhs)
    }
    
    public var magnitudeSquared: Double {
        first.magnitudeSquared + second.magnitudeSquared + third.magnitudeSquared
    }
}

public struct AnimatableTuple4<A: VectorArithmetic, B: VectorArithmetic, C: VectorArithmetic, D: VectorArithmetic>: VectorArithmetic {
    public var first: A
    public var second: B
    public var third: C
    public var fourth: D
    
    public init(_ first: A, _ second: B, _ third: C, _ fourth: D) {
        self.first = first
        self.second = second
        self.third = third
        self.fourth = fourth
    }
    
    public static var zero: Self { .init(.zero, .zero, .zero, .zero) }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        var copy = lhs
        copy += rhs
        return copy
    }
    
    public static func += (lhs: inout Self, rhs: Self) {
        lhs.first += rhs.first
        lhs.second += rhs.second
        lhs.third += rhs.third
        lhs.fourth += rhs.fourth
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        var copy = lhs
        copy -= rhs
        return copy
    }
    
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.first -= rhs.first
        lhs.second -= rhs.second
        lhs.third -= rhs.third
        lhs.fourth -= rhs.fourth
    }
    
    public mutating func scale(by rhs: Double) {
        first.scale(by: rhs)
        second.scale(by: rhs)
        third.scale(by: rhs)
        fourth.scale(by: rhs)
    }
    
    public var magnitudeSquared: Double {
        first.magnitudeSquared + second.magnitudeSquared + third.magnitudeSquared + fourth.magnitudeSquared
    }
}
