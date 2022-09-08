
import SwiftUI

// MARK: DispatchQueue extensions

public extension DispatchQueue {
    /// A global dispatch queue for background tasks.
    static let background = DispatchQueue.global(qos: .background)
}

// MARK: ColorScheme

extension ColorScheme: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self == .light)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if try container.decode(Bool.self) {
            self = .light
        }
        else {
            self = .dark
        }
    }
}

// MARK: Date extensions

public extension Calendar {
    static let gregorian: Calendar = Calendar(identifier: .gregorian)
    
    static let reference: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .utc
        
        return calendar
    }()
}

public extension TimeZone {
    static let utc = TimeZone(identifier: "UTC")!
}

public extension Date {
    fileprivate static let secondsPerDay: TimeInterval = 24 * 60 * 60
    
    var startOfDay: Date {
        let components = Calendar.reference.dateComponents([.day, .month, .year], from: self)
        return Calendar.reference.date(from: components)!
    }
    
    func convertToTimeZone(initTimeZone: TimeZone = .init(secondsFromGMT: 0)!, timeZone: TimeZone) -> Date {
        let delta = TimeInterval(timeZone.secondsFromGMT(for: self) - initTimeZone.secondsFromGMT(for: self))
        return addingTimeInterval(delta)
    }
    
    var startOfMonth: Date {
        let components = Calendar.reference.dateComponents([.year, .month], from: self)
        return Calendar.reference.date(from: components)!
    }
    
    var endOfMonth: Date {
        Calendar.reference.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth)!
    }
    
    var startOfWeek: Date {
        let components = Calendar.reference.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return Calendar.reference.date(from: components)!
    }
}

public extension Calendar {
    static func weekday(after day: Int) -> Int {
        switch day {
        case 7:
            return 1
        default:
            return day + 1
        }
    }
}

// MARK: VisualEffectView

#if canImport(UIKit)

/// Allows using UIVisualEffect in SwiftUI.
public struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    public init(effect: UIVisualEffect? = nil) {
        self.effect = effect
    }
    
    public func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView()
    }
    
    public func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect
    }
}

public extension View {
    /// Applies a UIBlurEffect to the background of this view.
    func blurredBackground(style: UIBlurEffect.Style) -> some View {
        self.background(VisualEffectView(effect: UIBlurEffect(style: style)))
    }
}

#endif

// MARK: View extensions

public extension View {
    /// Apply a modifier to this view only if the given condition is true.
    func applyIf<M: ViewModifier>(_ condition: Bool, _ modifier: M) -> some View {
        ZStack {
            if condition {
                self.modifier(modifier)
            }
            else {
                self
            }
        }
    }
}

// MARK: Share sheet

#if canImport(UIKit)

public func displayShareSheet(itemsToShare: [Any], sourceRect: CGRect? = nil) {
    guard let rootController = UIApplication.shared.windows.first?.rootViewController else {
        return
    }
    
    let activityViewController = UIActivityViewController(activityItems: itemsToShare,
                                                          applicationActivities: nil)
    
    activityViewController.popoverPresentationController?.sourceView = rootController.view
    activityViewController.popoverPresentationController?.sourceRect = sourceRect ??
        .init(x: UIScreen.main.bounds.width*0.5, y: UIScreen.main.bounds.height*0.5, width: 0, height: 0)
    
    rootController.present(activityViewController, animated: true, completion: nil)
}

#endif

// MARK: Coding

/// Makes you wish that Swift had variadic generics.
public extension KeyedEncodingContainer {
    mutating func encodeValues<V1: Encodable, V2: Encodable>(
        _ v1: V1,
        _ v2: V2,
        for key: Key
    ) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(v1)
        try container.encode(v2)
    }
    
    mutating func encodeValues<V1: Encodable, V2: Encodable, V3: Encodable>(
        _ v1: V1,
        _ v2: V2,
        _ v3: V3,
        for key: Key
    ) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(v1)
        try container.encode(v2)
        try container.encode(v3)
    }
    
    mutating func encodeValues<V1: Encodable, V2: Encodable, V3: Encodable, V4: Encodable>(
        _ v1: V1,
        _ v2: V2,
        _ v3: V3,
        _ v4: V4,
        for key: Key
    ) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(v1)
        try container.encode(v2)
        try container.encode(v3)
        try container.encode(v4)
    }
    
    mutating func encodeValues<V1: Encodable, V2: Encodable, V3: Encodable, V4: Encodable, V5: Encodable>(
        _ v1: V1,
        _ v2: V2,
        _ v3: V3,
        _ v4: V4,
        _ v5: V5,
        for key: Key
    ) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(v1)
        try container.encode(v2)
        try container.encode(v3)
        try container.encode(v4)
        try container.encode(v5)
    }
    
    mutating func encodeValues<V1: Encodable, V2: Encodable, V3: Encodable, V4: Encodable, V5: Encodable, V6: Encodable>(
        _ v1: V1,
        _ v2: V2,
        _ v3: V3,
        _ v4: V4,
        _ v5: V5,
        _ v6: V6,
        for key: Key
    ) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(v1)
        try container.encode(v2)
        try container.encode(v3)
        try container.encode(v4)
        try container.encode(v5)
        try container.encode(v6)
    }
    
    mutating func encodeValues<V1: Encodable, V2: Encodable, V3: Encodable, V4: Encodable, V5: Encodable, V6: Encodable, V7: Encodable>(
        _ v1: V1,
        _ v2: V2,
        _ v3: V3,
        _ v4: V4,
        _ v5: V5,
        _ v6: V6,
        _ v7: V7,
        for key: Key
    ) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(v1)
        try container.encode(v2)
        try container.encode(v3)
        try container.encode(v4)
        try container.encode(v5)
        try container.encode(v6)
        try container.encode(v7)
    }
}

public extension KeyedDecodingContainer {
    func decodeValues<V1: Decodable, V2: Decodable>(
        for key: Key
    ) throws -> (V1, V2) {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return (
            try container.decode(V1.self),
            try container.decode(V2.self)
        )
    }
    
    func decodeValues<V1: Decodable, V2: Decodable, V3: Decodable>(
        for key: Key
    ) throws -> (V1, V2, V3) {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return (
            try container.decode(V1.self),
            try container.decode(V2.self),
            try container.decode(V3.self)
        )
    }
    
    func decodeValues<V1: Decodable, V2: Decodable, V3: Decodable, V4: Decodable>(
        for key: Key
    ) throws -> (V1, V2, V3, V4) {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return (
            try container.decode(V1.self),
            try container.decode(V2.self),
            try container.decode(V3.self),
            try container.decode(V4.self)
        )
    }
    
    func decodeValues<V1: Decodable, V2: Decodable, V3: Decodable, V4: Decodable, V5: Decodable>(
        for key: Key
    ) throws -> (V1, V2, V3, V4, V5) {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return (
            try container.decode(V1.self),
            try container.decode(V2.self),
            try container.decode(V3.self),
            try container.decode(V4.self),
            try container.decode(V5.self)
        )
    }
    
    func decodeValues<V1: Decodable, V2: Decodable, V3: Decodable, V4: Decodable, V5: Decodable, V6: Decodable>(
        for key: Key
    ) throws -> (V1, V2, V3, V4, V5, V6) {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return (
            try container.decode(V1.self),
            try container.decode(V2.self),
            try container.decode(V3.self),
            try container.decode(V4.self),
            try container.decode(V5.self),
            try container.decode(V6.self)
        )
    }
    
    func decodeValues<V1: Decodable, V2: Decodable, V3: Decodable, V4: Decodable, V5: Decodable, V6: Decodable, V7: Decodable>(
        for key: Key
    ) throws -> (V1, V2, V3, V4, V5, V6, V7) {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return (
            try container.decode(V1.self),
            try container.decode(V2.self),
            try container.decode(V3.self),
            try container.decode(V4.self),
            try container.decode(V5.self),
            try container.decode(V6.self),
            try container.decode(V7.self)
        )
    }
}

