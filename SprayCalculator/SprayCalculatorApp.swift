import SwiftUI

@main
struct SprayCalculatorApp: App {
    @State private var localization = LocalizationManager()
    @State private var historyManager = HistoryManager()
    @State private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(localization)
                .environment(historyManager)
                .environment(favoritesManager)
        }
    }
}
