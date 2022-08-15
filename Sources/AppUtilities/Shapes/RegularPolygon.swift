
import SwiftUI

public struct RegularPolygon: Shape {
    /// The number of sides of this polygon.
    let sideCount: Int
    
    public func path(in rect: CGRect) -> Path {
        let radius = min(rect.height, rect.width) * 0.5
        let center = rect.center
        
        var path = Path()
        guard sideCount >= 3 else {
            path.addArc(center: center, radius: radius, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
            
            return path
        }
        
        let angleStep = 360.0 / Double(sideCount)
        let firstPt = center + pointOnCircle(radius: radius, angle: .zero)
        
        path.move(to: firstPt)
        
        for i in 1..<sideCount {
            let nextPt = pointOnCircle(radius: radius, angle: .init(degrees: Double(i) * angleStep))
            path.addLine(to: center + nextPt)
        }
        
        path.addLine(to: firstPt)
        
        return path
    }
}
