
import UIKit

public extension UIImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        self.init(cgImage: cgImage)
    }
    
    func multiplyColor(_ color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.clip(to: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height), mask: self.cgImage!)
        context?.fill(CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        let coloredImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return coloredImg!
    }
}

public extension UIImage {
    // https://stackoverflow.com/a/47402811/7564976
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// Add a border to the image.
    func withBorder(_ color: CGColor, width: CGFloat) -> UIImage? {
        guard let components = color.components else {
            return nil
        }
        
        let size = self.size
        UIGraphicsBeginImageContext(size)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.draw(in: rect, blendMode: .normal, alpha: 1)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(red: components[0], green: components[1], blue: components[2], alpha: components[3])
        context.setLineWidth(width)
        context.stroke(rect)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img
    }
}

public extension UIImage {
    var pixelWidth: Int {
        return cgImage?.width ?? 0
    }
    
    var pixelHeight: Int {
        return cgImage?.height ?? 0
    }
    
    func gridPoints(xStep: Int, yStep: Int) -> [CGPoint] {
        let xSteps = Int((self.size.width / CGFloat(xStep)).rounded(.up))
        let ySteps = Int((self.size.height / CGFloat(yStep)).rounded(.up))
        
        var pixels = [CGPoint]()
        for x in 0..<xSteps {
            let pixelX = min(self.size.width, CGFloat(x)*CGFloat(xStep))
            for y in 0..<ySteps {
                let pixelY = min(self.size.height, CGFloat(y)*CGFloat(yStep))
                pixels.append(.init(x: pixelX, y: pixelY))
            }
        }
        
        return pixels
    }
    
    func getPixelColors(xStep: Int, yStep: Int) throws -> [UIColor]? {
        try getColors(ofPixels: gridPoints(xStep: xStep, yStep: yStep))
    }
    
    func getColors(ofPixels pixels: [CGPoint]) throws -> [UIColor]? {
        guard
            let cgImage = cgImage,
            let data = cgImage.dataProvider?.data,
            let dataPtr = CFDataGetBytePtr(data),
            let colorSpaceModel = cgImage.colorSpace?.model,
            let componentLayout = cgImage.bitmapInfo.componentLayout
        else {
            throw "Could not get the color of a pixel in an image"
        }
        
        guard colorSpaceModel == .rgb else {
            throw "The only supported color space model is RGB"
        }
        
        guard cgImage.bitsPerPixel == 32 || cgImage.bitsPerPixel == 24 else {
            throw "A pixel is expected to be either 4 or 3 bytes in size"
        }
        
        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel/8
        
        var colors = [UIColor]()
        for pixel in pixels {
            let x = Int(pixel.x)
            let y = Int(pixel.y)
            
            guard 0..<pixelWidth ~= x && 0..<pixelHeight ~= y else {
                colors.append(.black)
                continue
            }
            
            let pixelOffset = y*bytesPerRow + x*bytesPerPixel
            if componentLayout.count == 4 {
                let components = (
                    dataPtr[pixelOffset + 0],
                    dataPtr[pixelOffset + 1],
                    dataPtr[pixelOffset + 2],
                    dataPtr[pixelOffset + 3]
                )
                
                var red, green, blue, alpha: UInt8
                switch componentLayout {
                case .bgra:
                    alpha = components.3
                    red = components.2
                    green = components.1
                    blue = components.0
                case .abgr:
                    alpha = components.0
                    red = components.3
                    green = components.2
                    blue = components.1
                case .argb:
                    alpha = components.0
                    red = components.1
                    green = components.2
                    blue = components.3
                case .rgba:
                    alpha = components.3
                    red = components.0
                    green = components.1
                    blue = components.2
                default:
                    alpha = 0
                    red = 0
                    green = 0
                    blue = 0
                }
                
                // If chroma components are premultiplied by alpha and the alpha is `0`,
                // keep the chroma components to their current values.
                if cgImage.bitmapInfo.chromaIsPremultipliedByAlpha && alpha != 0 {
                    let invUnitAlpha = 255/CGFloat(alpha)
                    red = UInt8((CGFloat(red)*invUnitAlpha).rounded())
                    green = UInt8((CGFloat(green)*invUnitAlpha).rounded())
                    blue = UInt8((CGFloat(blue)*invUnitAlpha).rounded())
                }
                
                colors.append(.init(red: red, green: green, blue: blue, alpha: alpha))
            }
            else if componentLayout.count == 3 {
                let components = (
                    dataPtr[pixelOffset + 0],
                    dataPtr[pixelOffset + 1],
                    dataPtr[pixelOffset + 2]
                )
                
                let red, green, blue: UInt8
                switch componentLayout {
                case .bgr:
                    red = components.2
                    green = components.1
                    blue = components.0
                case .rgb:
                    red = components.0
                    green = components.1
                    blue = components.2
                default:
                    red = 0
                    green = 0
                    blue = 0
                }
                
                colors.append(.init(red: red, green: green, blue: blue, alpha: UInt8(255)))
            }
            else {
                throw "Unsupported number of pixel components"
            }
        }
        
        return colors
    }
    
    func getPixelColor(pos: CGPoint) throws -> UIColor? {
        try getColors(ofPixels: [pos])?.first
    }
    
    func getPixelColor(x: Int, y: Int) throws -> UIColor? {
        try getColors(ofPixels: [CGPoint(x: CGFloat(x), y: CGFloat(y))])?.first
    }
    
}

public extension CGBitmapInfo {
    enum ComponentLayout {
        case bgra
        case abgr
        case argb
        case rgba
        case bgr
        case rgb
        
        var count: Int {
            switch self {
            case .bgr, .rgb: return 3
            default: return 4
            }
        }
        
    }
    
    var componentLayout: ComponentLayout? {
        guard let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) else { return nil }
        let isLittleEndian = contains(.byteOrder32Little)
        
        if alphaInfo == .none {
            return isLittleEndian ? .bgr : .rgb
        }
        
        let alphaIsFirst = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst
        if isLittleEndian {
            return alphaIsFirst ? .bgra : .abgr
        }
        else {
            return alphaIsFirst ? .argb : .rgba
        }
    }
    
    var chromaIsPremultipliedByAlpha: Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue)
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }
}

public extension UIView {
    func asImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

public extension UIScreen {
    var orientation: UIInterfaceOrientation {
        let point = coordinateSpace.convert(CGPoint.zero, to: fixedCoordinateSpace)
        switch (point.x, point.y) {
        case (0, 0):
            return .portrait
        case let (x, y) where x != 0 && y != 0:
            return .portraitUpsideDown
        case let (0, y) where y != 0:
            return .landscapeLeft
        case let (x, 0) where x != 0:
            return .landscapeRight
        default:
            return .unknown
        }
    }
}

public extension UIImage {
    /// Create a snapshot of this frame with the correct orientation.
    static func rotateSnapshotImage(from rawPhoto: UIImage) -> UIImage? {
        let rotationAngleDegrees: Float?
        switch UIScreen.main.orientation {
        case .portrait:
            rotationAngleDegrees = 90
        case .portraitUpsideDown:
            rotationAngleDegrees = -90
        case .landscapeLeft:
            rotationAngleDegrees = 180
        case .landscapeRight:
            rotationAngleDegrees = nil
        default:
            rotationAngleDegrees = nil
        }
        
        let finalPhoto: UIImage
        if let rotationAngleDegrees = rotationAngleDegrees {
            finalPhoto = rawPhoto.rotate(radians: rotationAngleDegrees * .deg2rad)!
        }
        else {
            finalPhoto = rawPhoto
        }
        
        return finalPhoto
    }
}

public extension CVPixelBuffer {
    /// Deep copy a CVPixelBuffer:
    /// http://stackoverflow.com/questions/38335365/pulling-data-from-a-cmsamplebuffer-in-order-to-create-a-deep-copy
    func copy() -> CVPixelBuffer {
        precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "copy() cannot be called on a non-CVPixelBuffer")
        
        var _copy: CVPixelBuffer?
        CVPixelBufferCreate(
            nil,
            CVPixelBufferGetWidth(self),
            CVPixelBufferGetHeight(self),
            CVPixelBufferGetPixelFormatType(self),
            CVBufferGetAttachments(self, .shouldPropagate),
            &_copy)
        
        guard let copy = _copy else { fatalError() }
        
        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(copy, [])
        
        defer {
            CVPixelBufferUnlockBaseAddress(copy, [])
            CVPixelBufferUnlockBaseAddress(self, .readOnly)
        }
        
        for plane in 0..<CVPixelBufferGetPlaneCount(self) {
            let dest = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
            let source = CVPixelBufferGetBaseAddressOfPlane(self, plane)
            let height = CVPixelBufferGetHeightOfPlane(self, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
            
            memcpy(dest, source, height * bytesPerRow)
        }
        
        return copy
    }
    
    /// Copy the contents of this buffer into another one.
    func copy(into copy: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(copy, [])
        
        defer {
            CVPixelBufferUnlockBaseAddress(copy, [])
            CVPixelBufferUnlockBaseAddress(self, .readOnly)
        }
        
        for plane in 0..<CVPixelBufferGetPlaneCount(self) {
            let dest = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
            let source = CVPixelBufferGetBaseAddressOfPlane(self, plane)
            let height = CVPixelBufferGetHeightOfPlane(self, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
            
            memcpy(dest, source, height * bytesPerRow)
        }
    }
}
