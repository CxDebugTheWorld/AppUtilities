
import Accelerate
import SwiftUI

// Adapted from https://developer.apple.com/documentation/accelerate/finding_the_sharpest_image_in_a_sequence_of_captured_images
public class BlurDetector: NSObject {
    let laplacian: [Float] = [-1, -1, -1,
                              -1,  8, -1,
                              -1, -1, -1]
    
    public func processImage(_ pixelBuffer: CVPixelBuffer) async throws -> BlurDetectionResult {
        CVPixelBufferLockBaseAddress(pixelBuffer,
                                     CVPixelBufferLockFlags.readOnly)
        
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let count = width * height
        
        let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
        let lumaRowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        
        let lumaCopy = UnsafeMutableRawPointer.allocate(byteCount: count,
                                                        alignment: MemoryLayout<Pixel_8>.alignment)
        lumaCopy.copyMemory(from: lumaBaseAddress!,
                            byteCount: count)
        
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer,
                                       CVPixelBufferLockFlags.readOnly)
        
        return try await withCheckedThrowingContinuation { continuation in
            defer {
                lumaCopy.deallocate()
            }
            
            let result = self.processImage(data: lumaCopy,
                                           rowBytes: lumaRowBytes,
                                           width: width,
                                           height: height,
                                           orientation: .up)
            
            guard let result else {
                continuation.resume(throwing: "processing image failed")
                return
            }
            
            continuation.resume(returning: result)
        }
    }
    
    private func processImage(data: UnsafeMutableRawPointer,
                              rowBytes: Int,
                              width: Int, height: Int,
                              orientation: CGImagePropertyOrientation) -> BlurDetectionResult? {
        var sourceBuffer = vImage_Buffer(data: data,
                                         height: vImagePixelCount(height),
                                         width: vImagePixelCount(width),
                                         rowBytes: rowBytes)
        
        var floatPixels: [Float]
        let count = width * height
        
        if sourceBuffer.rowBytes == width * MemoryLayout<Pixel_8>.stride {
            let start = sourceBuffer.data.assumingMemoryBound(to: Pixel_8.self)
            floatPixels = vDSP.integerToFloatingPoint(
                UnsafeMutableBufferPointer(start: start,
                                           count: count),
                floatingPointType: Float.self)
        }
        else {
            floatPixels = [Float](unsafeUninitializedCapacity: count) {
                buffer, initializedCount in
                
                var floatBuffer = vImage_Buffer(data: buffer.baseAddress,
                                                height: sourceBuffer.height,
                                                width: sourceBuffer.width,
                                                rowBytes: width * MemoryLayout<Float>.size)
                
                vImageConvert_Planar8toPlanarF(&sourceBuffer,
                                               &floatBuffer,
                                               0, 255,
                                               vImage_Flags(kvImageNoFlags))
                
                initializedCount = count
            }
        }
        
        // Convolve with Laplacian.
        vDSP.convolve(floatPixels,
                      rowCount: height,
                      columnCount: width,
                      with3x3Kernel: laplacian,
                      result: &floatPixels)
        
        // Calculate standard deviation.
        var mean = Float.nan
        var stdDev = Float.nan
        
        vDSP_normalize(floatPixels, 1,
                       nil, 1,
                       &mean, &stdDev,
                       vDSP_Length(count))
        
        return stdDev * stdDev
    }
}

// MARK: BlurDetectionResult

public typealias BlurDetectionResult = Float

// Extensions to simplify conversion between orientation enums.
public extension UIImage.Orientation {
    init(_ cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        }
    }
}
