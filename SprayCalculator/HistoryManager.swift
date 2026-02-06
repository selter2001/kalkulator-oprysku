import SwiftUI

class HistoryManager: ObservableObject {
    @Published var calculations: [SprayCalculation] = []
    
    private let storageKey = "sprayCalculationHistory"
    private let maxHistoryItems = 50
    
    init() {
        loadHistory()
    }
    
    func addCalculation(_ calculation: SprayCalculation) {
        calculations.insert(calculation, at: 0)
        
        // Keep only last 50 calculations
        if calculations.count > maxHistoryItems {
            calculations = Array(calculations.prefix(maxHistoryItems))
        }
        
        saveHistory()
    }
    
    func deleteCalculation(at indexSet: IndexSet) {
        calculations.remove(atOffsets: indexSet)
        saveHistory()
    }
    
    func clearHistory() {
        calculations.removeAll()
        saveHistory()
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SprayCalculation].self, from: data) else {
            return
        }
        calculations = decoded
    }
    
    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(calculations) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }
}
