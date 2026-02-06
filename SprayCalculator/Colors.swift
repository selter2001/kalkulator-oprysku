import SwiftUI

extension Color {
    // MARK: - Primary Colors (Green)
    static let primaryGreen = Color(red: 0.18, green: 0.54, blue: 0.34)
    static let lightGreen = Color(red: 0.40, green: 0.73, blue: 0.42)
    static let darkGreen = Color(red: 0.10, green: 0.36, blue: 0.22)
    
    // MARK: - Secondary Colors (Brown/Earth)
    static let earthBrown = Color(red: 0.55, green: 0.38, blue: 0.24)
    static let lightBrown = Color(red: 0.76, green: 0.60, blue: 0.42)
    static let darkBrown = Color(red: 0.36, green: 0.25, blue: 0.15)
    
    // MARK: - Accent Colors
    static let accentGold = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let waterBlue = Color(red: 0.25, green: 0.61, blue: 0.76)
    
    // MARK: - Background Colors
    static let backgroundLight = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let backgroundCard = Color.white
    static let backgroundDark = Color(red: 0.12, green: 0.14, blue: 0.13)
    
    // MARK: - Text Colors
    static let textPrimary = Color(red: 0.15, green: 0.15, blue: 0.14)
    static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.43)
    
    // MARK: - Semantic Colors
    static let success = Color.lightGreen
    static let warning = Color.accentGold
    static let error = Color(red: 0.85, green: 0.30, blue: 0.25)
}

// MARK: - Gradients
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [Color.primaryGreen, Color.darkGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let earthGradient = LinearGradient(
        colors: [Color.lightBrown, Color.earthBrown],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [Color.backgroundLight, Color(red: 0.92, green: 0.90, blue: 0.85)],
        startPoint: .top,
        endPoint: .bottom
    )
}
