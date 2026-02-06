import SwiftUI

@main
struct SprayCalculatorApp: App {
    @StateObject private var localization = LocalizationManager()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var favoritesManager = FavoritesManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localization)
                .environmentObject(historyManager)
                .environmentObject(favoritesManager)
        }
    }
}
