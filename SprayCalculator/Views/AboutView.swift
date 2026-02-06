import SwiftUI

struct AboutView: View {
    @Environment(LocalizationManager.self) private var localization

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        List {
            // App Info Section
            Section {
                Label(localization.appTitle, systemImage: "leaf.fill")
                    .foregroundStyle(Color(.textPrimary))
                    .labelStyle(AboutLabelStyle(iconColor: Color(.primaryGreen)))

                HStack {
                    Text(localization.version)
                        .foregroundStyle(Color(.textPrimary))
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundStyle(Color(.textSecondary))
                }

                HStack {
                    Text("iOS")
                        .foregroundStyle(Color(.textPrimary))
                    Spacer()
                    Text("17.0+")
                        .foregroundStyle(Color(.textSecondary))
                }
            }
            .listRowBackground(Color(.backgroundCard))

            // Author Section
            Section {
                Label("Wojciech Olszak", systemImage: "person.fill")
                    .foregroundStyle(Color(.textPrimary))

                Link(destination: URL(string: "https://github.com/selter2001/kalkulator-oprysku")!) {
                    Label("GitHub", systemImage: "link")
                        .foregroundStyle(Color(.primaryGreen))
                }
            } header: {
                Text(localization.author)
                    .font(.subheadline)
                    .foregroundStyle(Color(.textSecondary))
            }
            .listRowBackground(Color(.backgroundCard))
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppGradients.backgroundGradient.ignoresSafeArea())
        .navigationTitle(localization.about)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Custom Label Style
struct AboutLabelStyle: LabelStyle {
    let iconColor: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundStyle(iconColor)
            configuration.title
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
            .environment(LocalizationManager())
    }
}
