import SwiftUI

struct FontManager {
    static func rounded(size: CGFloat, weight: Font.Weight) -> Font {
        return Font.system(size: size, weight: weight, design: .rounded)
    }
}

struct ColorManager {
    static let background = Color("NearbyBackgroundColor")
    static let cardBackground = Color("NearbyCardBackgroundColor")
    static let text = Color("NearbyTextColor")
    static let secondaryText = Color("NearbySecondaryTextColor")
    static let placeholderBackground = Color("NearbyPlaceholderBackgroundColor")
    static let placeholderText = Color("NearbyPlaceholderTextColor")
}
