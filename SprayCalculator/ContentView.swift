import SwiftUI

struct ContentView: View {
    @Environment(LocalizationManager.self) private var localization
    @Environment(HistoryManager.self) private var historyManager
    @Environment(FavoritesManager.self) private var favoritesManager

    @State private var selectedTab = 0
    @State private var calculatorViewKey = UUID()

    // Reference to calculator view for loading favorites
    @State private var selectedFavorite: FavoriteConfiguration?

    // CalcViewModel — created lazily because @Environment is not available in init()
    @State private var viewModel: CalcViewModel?

    var body: some View {
        Group {
            if let viewModel {
                mainContent(viewModel: viewModel)
            } else {
                Color.clear
            }
        }
        .task {
            if viewModel == nil {
                viewModel = CalcViewModel(historyManager: historyManager)
            }
        }
        .onChange(of: localization.currentLanguage) {
            // Force refresh when language changes
            calculatorViewKey = UUID()
        }
    }

    private func mainContent(viewModel: CalcViewModel) -> some View {
        TabView(selection: $selectedTab) {
            // Calculator Tab
            NavigationStack {
                CalculatorViewWrapper(viewModel: viewModel, selectedFavorite: $selectedFavorite)
                    .id(calculatorViewKey)
                    .navigationTitle(localization.appTitle)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.primaryGreen)
                            }
                        }
                    }
            }
            .tabItem {
                Label {
                    Text(localization.calculate)
                } icon: {
                    Image(systemName: "function")
                }
            }
            .tag(0)

            // History Tab
            NavigationStack {
                HistoryView()
                    .navigationTitle(localization.history)
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label {
                    Text(localization.history)
                } icon: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            .tag(1)

            // Favorites Tab
            NavigationStack {
                FavoritesView { favorite in
                    selectedFavorite = favorite
                    selectedTab = 0
                }
                .navigationTitle(localization.favorites)
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label {
                    Text(localization.favorites)
                } icon: {
                    Image(systemName: "star.fill")
                }
            }
            .tag(2)
        }
        .tint(.primaryGreen)
    }
}

// MARK: - Calculator View Wrapper
struct CalculatorViewWrapper: View {
    @Bindable var viewModel: CalcViewModel
    @Binding var selectedFavorite: FavoriteConfiguration?

    var body: some View {
        CalculatorViewWithFavorite(viewModel: viewModel, selectedFavorite: $selectedFavorite)
    }
}

struct CalculatorViewWithFavorite: View {
    @Bindable var viewModel: CalcViewModel
    @Environment(LocalizationManager.self) private var localization
    @Environment(FavoritesManager.self) private var favoritesManager

    @Binding var selectedFavorite: FavoriteConfiguration?

    // UI-only state
    @State private var showSaveDialog = false
    @State private var favoriteName: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Area unit picker
                areaUnitPicker

                // Input fields
                inputFieldsSection

                // Action buttons
                actionButtons

                // Results
                if viewModel.showResults, let result = viewModel.calculationResult {
                    resultsSection(result: result)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(LinearGradient.backgroundGradient.ignoresSafeArea())
        .overlay {
            if viewModel.showAnimation {
                TractorSprayingAnimation {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        viewModel.onAnimationComplete()
                    }
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showSaveDialog) {
            saveToFavoritesSheet
        }
        .alert(viewModel.errorMessage, isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: selectedFavorite) {
            if let favorite = selectedFavorite {
                viewModel.loadFavorite(favorite)
                selectedFavorite = nil
            }
        }
    }

    // MARK: - Area Unit Picker
    private var areaUnitPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.areaUnitLabel)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)

            Picker("", selection: $viewModel.selectedAreaUnit) {
                ForEach(AreaUnit.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Input Fields
    private var inputFieldsSection: some View {
        VStack(spacing: 16) {
            SprayInputField(
                title: localization.fieldArea,
                unit: viewModel.selectedAreaUnit.displayName,
                value: $viewModel.fieldAreaText,
                icon: "square.dashed",
                isShaking: viewModel.shakingFields.contains("fieldArea")
            )

            SprayInputField(
                title: localization.sprayRate,
                unit: localization.sprayRateUnit,
                value: $viewModel.sprayRateText,
                icon: "drop.fill",
                isShaking: viewModel.shakingFields.contains("sprayRate")
            )

            SprayInputField(
                title: localization.chemicalRate,
                unit: localization.chemicalRateUnit,
                value: $viewModel.chemicalRateText,
                icon: "flask.fill",
                isShaking: viewModel.shakingFields.contains("chemicalRate")
            )

            SprayInputField(
                title: localization.tankCapacity,
                unit: localization.tankCapacityUnit,
                value: $viewModel.tankCapacityText,
                icon: "fuelpump.fill",
                isShaking: viewModel.shakingFields.contains("tankCapacity")
            )
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: localization.calculate,
                icon: "play.fill",
                action: {
                    viewModel.calculate(invalidValueError: localization.invalidValueError)
                }
            )

            HStack(spacing: 12) {
                SecondaryButton(
                    title: localization.clear,
                    icon: "trash",
                    action: {
                        withAnimation {
                            viewModel.clear()
                        }
                    }
                )

                if viewModel.calculationResult != nil {
                    SecondaryButton(
                        title: localization.saveToFavorites,
                        icon: "star",
                        action: { showSaveDialog = true }
                    )
                }
            }
        }
    }

    // MARK: - Results Section
    private func resultsSection(result: SprayCalculation) -> some View {
        VStack(spacing: 16) {
            SectionHeader(title: localization.results, icon: "chart.bar.fill")

            ResultCard(
                icon: "💧",
                title: localization.workingFluid,
                value: viewModel.formatNumber(result.totalWorkingFluid),
                unit: localization.liters,
                delay: 0.1
            )

            ResultCard(
                icon: "🧪",
                title: localization.chemical,
                value: viewModel.formatNumber(result.totalChemical),
                unit: localization.liters,
                detail: "\(viewModel.formatNumber(result.chemicalPerTank)) l / \(localization.tankCapacity.lowercased())",
                delay: 0.2
            )

            ResultCard(
                icon: "🚜",
                title: localization.tankFills,
                value: viewModel.tankFillsDescription(result, fullTanksLabel: localization.fullTanks, partialTankLabel: localization.partialTank),
                unit: "",
                detail: result.hasPartialTank ? "\(localization.partialTank): \(viewModel.formatNumber(result.partialTankVolume)) l" : nil,
                delay: 0.3
            )

            // CALC-01: Full tank composition (water + chemical)
            ResultCard(
                icon: "🪣",
                title: localization.fullTankComposition,
                value: "\(viewModel.formatNumber(result.waterPerFullTank)) l + \(viewModel.formatNumber(result.chemicalPerTank)) l",
                unit: "",
                detail: "\(localization.water) + \(localization.chemical)",
                delay: 0.4
            )

            // CALC-02: Partial tank composition (conditional)
            if result.hasPartialTank {
                ResultCard(
                    icon: "🫗",
                    title: localization.partialTankComposition,
                    value: "\(viewModel.formatNumber(result.waterForPartialTank)) l + \(viewModel.formatNumber(result.chemicalForPartialTank)) l",
                    unit: "",
                    detail: "\(localization.water) + \(localization.chemical)",
                    delay: 0.5
                )
            }

            // CALC-03: Total chemical to buy
            ResultCard(
                icon: "🛒",
                title: localization.totalChemicalToBuy,
                value: viewModel.formatNumber(result.totalChemical),
                unit: localization.liters,
                delay: 0.6
            )
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Save Dialog
    private var saveToFavoritesSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(localization.saveToFavorites)
                    .font(.title2)
                    .fontWeight(.bold)

                TextField(localization.configurationName, text: $favoriteName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button(localization.save) {
                    saveFavorite()
                }
                .buttonStyle(.borderedProminent)
                .tint(.primaryGreen)
                .disabled(favoriteName.isEmpty)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.cancel) {
                        showSaveDialog = false
                        favoriteName = ""
                    }
                }
            }
        }
        .presentationDetents([.height(200)])
    }

    // MARK: - Helper Methods
    private func saveFavorite() {
        let favorite = FavoriteConfiguration(
            name: favoriteName,
            sprayRate: viewModel.parseNumber(viewModel.sprayRateText) ?? 0,
            chemicalRate: viewModel.parseNumber(viewModel.chemicalRateText) ?? 0,
            tankCapacity: viewModel.parseNumber(viewModel.tankCapacityText) ?? 0,
            areaUnit: viewModel.selectedAreaUnit
        )
        favoritesManager.addFavorite(favorite)
        showSaveDialog = false
        favoriteName = ""
    }
}

#Preview {
    ContentView()
        .environment(LocalizationManager())
        .environment(HistoryManager())
        .environment(FavoritesManager())
}
