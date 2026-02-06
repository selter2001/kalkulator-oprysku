import SwiftUI

struct SettingsView: View {
    @Environment(LocalizationManager.self) private var localization
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Language Section
            Section {
                ForEach(Language.allCases, id: \.self) { language in
                    LanguageRow(
                        language: language,
                        isSelected: localization.currentLanguage == language,
                        onSelect: {
                            withAnimation {
                                localization.currentLanguage = language
                            }
                        }
                    )
                }
            } header: {
                Text(localization.language)
                    .font(.subheadline)
                    .foregroundStyle(Color(.textSecondary))
            }
            .listRowBackground(Color(.backgroundCard))

            // App Info Section
            Section {
                HStack {
                    Text(localization.version)
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(Color(.textSecondary))
                }

                HStack {
                    Text("iOS")
                    Spacer()
                    Text("17.0+")
                        .foregroundStyle(Color(.textSecondary))
                }
            } header: {
                Text(localization.information)
                    .font(.subheadline)
                    .foregroundStyle(Color(.textSecondary))
            }
            .listRowBackground(Color(.backgroundCard))
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppGradients.backgroundGradient.ignoresSafeArea())
        .navigationTitle(localization.settings)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Language Row
struct LanguageRow: View {
    let language: Language
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(language.flag)
                    .font(.title2)

                Text(language.displayName)
                    .foregroundStyle(Color(.textPrimary))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(.primaryGreen))
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(LocalizationManager())
    }
}
