
import SwiftUI

enum AUIcon {
    /// A system icon.
    case System(systemName: String, rotation: Angle = .zero, scale: CGFloat = 1)
    
    /// A custom image icon.
    case Image(name: String, rotation: Angle = .zero, scale: CGFloat = 1)
    
    /// A custom image icon.
    case LoadedImage(image: UIImage, rotation: Angle = .zero, scale: CGFloat = 1)
    
    /// A text-based icon.
    case Text(text: String, rotation: Angle = .zero, scale: CGFloat = 1)
    
    /// A placeholder icon.
    case Placeholder
}

extension AUIcon {
    /// Create a view for this icon.
    func createView(color: Color, size: CGFloat) -> some View {
        AUIconView(icon: self, color: color, size: .init(width: size, height: size))
    }
    
    /// Create a view for this icon.
    func createView(color: Color, size: CGSize) -> some View {
        AUIconView(icon: self, color: color, size: size)
    }
}

struct AUIconView: View {
    /// The icon this view is for.
    let icon: AUIcon
    
    /// The color of the icon.
    let color: Color
    
    /// The size of the icon.
    let size: CGSize
    
    var body: some View {
        ZStack {
            switch icon {
            case .System(let systemName, let rotation, let scale):
                Image(systemName: systemName)
                    .font(.system(size: size.width))
                    .foregroundColor(color)
                    .rotationEffect(rotation)
                    .scaleEffect(scale)
            case .Image(let name, let rotation, let scale):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .colorMultiply(color)
                    .rotationEffect(rotation)
                    .scaleEffect(scale)
            case .LoadedImage(let image, let rotation, let scale):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .colorMultiply(color)
                    .rotationEffect(rotation)
                    .scaleEffect(scale)
            case .Text(let text, let rotation, let scale):
                Text(verbatim: text)
                    .font(.system(size: size.width))
                    .foregroundColor(color)
                    .rotationEffect(rotation)
                    .scaleEffect(scale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            case .Placeholder:
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: size.width, height: size.height)
            }
        }
    }
}

extension AUIcon: Codable {
    enum CodingKeys: CodingKey {
        case systemImage, image, text, placeholder, loadedImage
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .System(let systemName, let rotation, let scale):
            try container.encodeValues(systemName, rotation.degrees, scale, for: .systemImage)
        case .Image(let name, let rotation, let scale):
            try container.encodeValues(name, rotation.degrees, scale, for: .image)
        case .LoadedImage(let image, let rotation, let scale):
            try container.encodeValues(image.pngData(), rotation.degrees, scale, for: .loadedImage)
        case .Text(let text, let rotation, let scale):
            try container.encodeValues(text, rotation.degrees, scale, for: .text)
        case .Placeholder:
            try container.encodeNil(forKey: .placeholder)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .systemImage:
            let (systemName, rotationDegrees, scale): (String, Double, CGFloat) = try container.decodeValues(for: .systemImage)
            self = .System(systemName: systemName, rotation: .init(degrees: rotationDegrees), scale: scale)
        case .image:
            let (name, rotationDegrees, scale): (String, Double, CGFloat) = try container.decodeValues(for: .image)
            self = .Image(name: name, rotation: .init(degrees: rotationDegrees), scale: scale)
        case .loadedImage:
            let (imgData, rotationDegrees, scale): (Data?, Double, CGFloat) =
            try container.decodeValues(for: .loadedImage)
            
            guard let imgData = imgData else {
                reportCriticalError("AUIcon: UIImage is missing data")
                self = .Placeholder
                
                return
            }
            
            guard let img = UIImage(data: imgData) else {
                reportCriticalError("AUIcon: decoding UIImage failed")
                self = .Placeholder
                
                return
            }
            
            self = .LoadedImage(image: img, rotation: .init(degrees: rotationDegrees), scale: scale)
        case .text:
            let (text, rotationDegrees, scale): (String, Double, CGFloat) = try container.decodeValues(for: .text)
            self = .Text(text: text, rotation: .init(degrees: rotationDegrees), scale: scale)
        case .placeholder:
            _ = try container.decodeNil(forKey: .placeholder)
            self = .Placeholder
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode enum AUIcon."
                )
            )
        }
    }
}

