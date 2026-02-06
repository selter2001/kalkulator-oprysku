import SwiftUI

struct ContentView: View {
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    @State private var selectedTab = 0
    @State private var calculatorViewKey = UUID()
    
    // Reference to calculator view for loading favorites
    @State private var selectedFavorite: FavoriteConfiguration?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Calculator Tab
            NavigationStack {
                CalculatorViewWrapper(selectedFavorite: $selectedFavorite)
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
        .onChange(of: localization.currentLanguage) {
            // Force refresh when language changes
            calculatorViewKey = UUID()
        }
    }
}

// MARK: - Calculator View Wrapper
struct CalculatorViewWrapper: View {
    @Binding var selectedFavorite: FavoriteConfiguration?
    
    var body: some View {
        CalculatorViewWithFavorite(selectedFavorite: $selectedFavorite)
    }
}

struct CalculatorViewWithFavorite: View {
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    @Binding var selectedFavorite: FavoriteConfiguration?
    
    // Input values
    @State private var fieldArea: String = ""
    @State private var sprayRate: String = ""
    @State private var chemicalRate: String = ""
    @State private var tankCapacity: String = ""
    @State private var selectedAreaUnit: AreaUnit = .hectares
    
    // UI State
    @State private var calculationResult: SprayCalculation?
    @State private var showResults = false
    @State private var showAnimation = false
    @State private var showSaveDialog = false
    @State private var favoriteName: String = ""
    @State private var shakingFields: Set<String> = []
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                if showResults, let result = calculationResult {
                    resultsSection(result: result)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(LinearGradient.backgroundGradient.ignoresSafeArea())
        .overlay {
            if showAnimation {
                TractorSprayingAnimation {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showAnimation = false
                        showResults = true
                    }
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showSaveDialog) {
            saveToFavoritesSheet
        }
        .alert(errorMessage, isPresented: $showError) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: selectedFavorite) {
            if let favorite = selectedFavorite {
                loadFavorite(favorite)
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
            
            Picker("", selection: $selectedAreaUnit) {
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
                unit: selectedAreaUnit.displayName,
                value: $fieldArea,
                icon: "square.dashed",
                isShaking: shakingFields.contains("fieldArea")
            )
            
            SprayInputField(
                title: localization.sprayRate,
                unit: localization.sprayRateUnit,
                value: $sprayRate,
                icon: "drop.fill",
                isShaking: shakingFields.contains("sprayRate")
            )
            
            SprayInputField(
                title: localization.chemicalRate,
                unit: localization.chemicalRateUnit,
                value: $chemicalRate,
                icon: "flask.fill",
                isShaking: shakingFields.contains("chemicalRate")
            )
            
            SprayInputField(
                title: localization.tankCapacity,
                unit: localization.tankCapacityUnit,
                value: $tankCapacity,
                icon: "fuelpump.fill",
                isShaking: shakingFields.contains("tankCapacity")
            )
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: localization.calculate,
                icon: "play.fill",
                action: performCalculation
            )
            
            HStack(spacing: 12) {
                SecondaryButton(
                    title: localization.clear,
                    icon: "trash",
                    action: clearFields
                )
                
                if calculationResult != nil {
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
                value: formatNumber(result.totalWorkingFluid),
                unit: localization.liters,
                delay: 0.1
            )
            
            ResultCard(
                icon: "🧪",
                title: localization.chemical,
                value: formatNumber(result.totalChemical),
                unit: localization.liters,
                detail: "\(formatNumber(result.chemicalPerTank)) l / \(localization.tankCapacity.lowercased())",
                delay: 0.2
            )
            
            ResultCard(
                icon: "🚜",
                title: localization.tankFills,
                value: tankFillsDescription(result),
                unit: "",
                detail: result.hasPartialTank ? "\(localization.partialTank): \(formatNumber(result.partialTankVolume)) l" : nil,
                delay: 0.3
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
    private func performCalculation() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        let fields = validateFields()
        guard fields.isValid else {
            shakeInvalidFields(fields.invalidFields)
            return
        }
        
        guard let area = parseNumber(fieldArea),
              let spray = parseNumber(sprayRate),
              let chemical = parseNumber(chemicalRate),
              let tank = parseNumber(tankCapacity) else {
            errorMessage = localization.invalidValueError
            showError = true
            return
        }
        
        let calculation = SprayCalculation(
            fieldArea: area,
            areaUnit: selectedAreaUnit,
            sprayRate: spray,
            chemicalRate: chemical,
            tankCapacity: tank
        )
        
        calculationResult = calculation
        historyManager.addCalculation(calculation)
        
        withAnimation {
            showResults = false
            showAnimation = true
        }
    }
    
    private func validateFields() -> (isValid: Bool, invalidFields: [String]) {
        var invalidFields: [String] = []
        
        if fieldArea.isEmpty { invalidFields.append("fieldArea") }
        if sprayRate.isEmpty { invalidFields.append("sprayRate") }
        if chemicalRate.isEmpty { invalidFields.append("chemicalRate") }
        if tankCapacity.isEmpty { invalidFields.append("tankCapacity") }
        
        return (invalidFields.isEmpty, invalidFields)
    }
    
    private func shakeInvalidFields(_ fields: [String]) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        withAnimation(.default) {
            shakingFields = Set(fields)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                shakingFields.removeAll()
            }
        }
    }
    
    private func clearFields() {
        withAnimation {
            fieldArea = ""
            sprayRate = ""
            chemicalRate = ""
            tankCapacity = ""
            calculationResult = nil
            showResults = false
        }
    }
    
    private func saveFavorite() {
        let favorite = FavoriteConfiguration(
            name: favoriteName,
            sprayRate: parseNumber(sprayRate) ?? 0,
            chemicalRate: parseNumber(chemicalRate) ?? 0,
            tankCapacity: parseNumber(tankCapacity) ?? 0,
            areaUnit: selectedAreaUnit
        )
        favoritesManager.addFavorite(favorite)
        showSaveDialog = false
        favoriteName = ""
    }
    
    private func loadFavorite(_ favorite: FavoriteConfiguration) {
        withAnimation {
            sprayRate = formatNumber(favorite.sprayRate)
            chemicalRate = formatNumber(favorite.chemicalRate)
            tankCapacity = formatNumber(favorite.tankCapacity)
            selectedAreaUnit = favorite.areaUnit
        }
    }
    
    private func parseNumber(_ string: String) -> Double? {
        let normalized = string.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
    
    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func tankFillsDescription(_ result: SprayCalculation) -> String {
        if result.fullTanks > 0 && result.hasPartialTank {
            return "\(result.fullTanks) \(localization.fullTanks) + 1 \(localization.partialTank)"
        } else if result.fullTanks > 0 {
            return "\(result.fullTanks) \(localization.fullTanks)"
        } else if result.hasPartialTank {
            return "1 \(localization.partialTank)"
        }
        return "0"
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager())
        .environmentObject(HistoryManager())
        .environmentObject(FavoritesManager())
}
