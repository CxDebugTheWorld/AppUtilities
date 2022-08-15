
import SwiftUI

public struct PreviewContainer<Content: View>: View {
    let colorSchemes: [ColorScheme]
    let devices: [DeviceModel]
    let content: () -> Content
    
    public init(colorSchemes: [ColorScheme] = [.light, .dark], devices: [DeviceModel] = [.iPhone12mini],
                @ViewBuilder content: @escaping () -> Content) {
        self.colorSchemes = colorSchemes
        self.devices = devices
        self.content = content
    }
    
    public var body: some View {
        ForEach(devices, id: \.self) { device in
            ForEach(colorSchemes, id: \.self) { scheme in
                HStack(spacing: 0, content: content)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environment(\.colorScheme, scheme)
                    .previewDevice(.init(rawValue: device.rawValue))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
