import SwiftUI

struct FavoritesView: View {
    @Environment(LocalizationManager.self) private var localization
    @Environment(FavoritesManager.self) private var favoritesManager
    
    let onSelectFavorite: (FavoriteConfiguration) -> Void
    
    var body: some View {
        Group {
            if favoritesManager.favorites.isEmpty {
                emptyState
            } else {
                favoritesList
            }
        }
        .background(LinearGradient.backgroundGradient.ignoresSafeArea())
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.textSecondary.opacity(0.5))
            
            Text(localization.noFavorites)
                .font(.headline)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Favorites List
    private var favoritesList: some View {
        List {
            ForEach(favoritesManager.favorites) { favorite in
                FavoriteRowView(
                    favorite: favorite,
                    onUse: {
                        onSelectFavorite(favorite)
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: favoritesManager.deleteFavorite)
        }
        .listStyle(.plain)
    }
}

// MARK: - Favorite Row View
struct FavoriteRowView: View {
    @Environment(LocalizationManager.self) private var localization
    let favorite: FavoriteConfiguration
    let onUse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.accentGold)
                
                Text(favorite.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: onUse) {
                    Text(localization.use)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.primaryGreen)
                        )
                }
            }
            
            // Details
            HStack(spacing: 16) {
                MiniDetailView(icon: "drop.fill", value: "\(formatNumber(favorite.sprayRate)) l/ha")
                MiniDetailView(icon: "flask.fill", value: "\(formatNumber(favorite.chemicalRate)) l/ha")
                MiniDetailView(icon: "fuelpump.fill", value: "\(formatNumber(favorite.tankCapacity)) l")
            }
            
            Text(formatDate(favorite.dateCreated))
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundCard)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
    
    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Mini Detail View
struct MiniDetailView: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.primaryGreen)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView(onSelectFavorite: { _ in })
            .environment(LocalizationManager())
            .environment(FavoritesManager())
    }
}
