import SwiftUI

// MARK: - Adaptive Gradients
// Colors adapt automatically via Asset Catalog light/dark variants.
// Use @Environment(\.colorScheme) only if gradient STRUCTURE needs to change between modes.
enum AppGradients {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(.gradientStart), Color(.gradientEnd)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(.backgroundGradientStart), Color(.backgroundGradientEnd)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var earthGradient: LinearGradient {
        LinearGradient(
            colors: [Color(.lightBrown), Color(.earthBrown)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
