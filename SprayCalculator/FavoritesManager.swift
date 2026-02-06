import SwiftUI

class FavoritesManager: ObservableObject {
    @Published var favorites: [FavoriteConfiguration] = []
    
    private let storageKey = "sprayFavoriteConfigurations"
    
    init() {
        loadFavorites()
    }
    
    func addFavorite(_ favorite: FavoriteConfiguration) {
        favorites.insert(favorite, at: 0)
        saveFavorites()
    }
    
    func deleteFavorite(at indexSet: IndexSet) {
        favorites.remove(atOffsets: indexSet)
        saveFavorites()
    }
    
    func deleteFavorite(_ favorite: FavoriteConfiguration) {
        favorites.removeAll { $0.id == favorite.id }
        saveFavorites()
    }
    
    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FavoriteConfiguration].self, from: data) else {
            return
        }
        favorites = decoded
    }
    
    private func saveFavorites() {
        guard let encoded = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }
}
