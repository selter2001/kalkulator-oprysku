import Observation
import Foundation
import UIKit

@Observable
class CalcViewModel {
    // MARK: - Input State (bound to TextFields)
    var fieldAreaText: String = ""
    var sprayRateText: String = ""
    var chemicalRateText: String = ""
    var tankCapacityText: String = ""
    var selectedAreaUnit: AreaUnit = .hectares

    // MARK: - Output State
    var calculationResult: SprayCalculation?
    var showResults: Bool = false
    var showAnimation: Bool = false
    var shakingFields: Set<String> = []
    var showError: Bool = false
    var errorMessage: String = ""

    // MARK: - Dependencies
    private let calculator = SprayCalculatorService()
    private let historyManager: HistoryManager

    init(historyManager: HistoryManager) {
        self.historyManager = historyManager
    }

    // MARK: - Actions
    func calculate(invalidValueError: String) {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )

        let fields = validateFields()
        guard fields.isValid else {
            shakeInvalidFields(fields.invalidFields)
            return
        }

        guard let area = parseNumber(fieldAreaText),
              let spray = parseNumber(sprayRateText),
              let chemical = parseNumber(chemicalRateText),
              let tank = parseNumber(tankCapacityText) else {
            errorMessage = invalidValueError
            showError = true
            return
        }

        let result = calculator.calculate(
            fieldArea: area,
            areaUnit: selectedAreaUnit,
            sprayRate: spray,
            chemicalRate: chemical,
            tankCapacity: tank
        )

        calculationResult = result
        historyManager.addCalculation(result)

        showResults = false
        showAnimation = true
    }

    func onAnimationComplete() {
        showAnimation = false
        showResults = true
    }

    func clear() {
        fieldAreaText = ""
        sprayRateText = ""
        chemicalRateText = ""
        tankCapacityText = ""
        calculationResult = nil
        showResults = false
    }

    func loadFavorite(_ favorite: FavoriteConfiguration) {
        sprayRateText = formatNumber(favorite.sprayRate)
        chemicalRateText = formatNumber(favorite.chemicalRate)
        tankCapacityText = formatNumber(favorite.tankCapacity)
        selectedAreaUnit = favorite.areaUnit
    }

    // MARK: - Formatting
    func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    func tankFillsDescription(
        _ result: SprayCalculation,
        fullTanksLabel: String,
        partialTankLabel: String
    ) -> String {
        if result.fullTanks > 0 && result.hasPartialTank {
            return "\(result.fullTanks) \(fullTanksLabel) + 1 \(partialTankLabel)"
        } else if result.fullTanks > 0 {
            return "\(result.fullTanks) \(fullTanksLabel)"
        } else if result.hasPartialTank {
            return "1 \(partialTankLabel)"
        }
        return "0"
    }

    // MARK: - Parsing
    func parseNumber(_ string: String) -> Double? {
        let normalized = string.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    // MARK: - Private
    private func validateFields() -> (isValid: Bool, invalidFields: [String]) {
        var invalid: [String] = []
        if fieldAreaText.isEmpty { invalid.append("fieldArea") }
        if sprayRateText.isEmpty { invalid.append("sprayRate") }
        if chemicalRateText.isEmpty { invalid.append("chemicalRate") }
        if tankCapacityText.isEmpty { invalid.append("tankCapacity") }
        return (invalid.isEmpty, invalid)
    }

    private func shakeInvalidFields(_ fields: [String]) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        shakingFields = Set(fields)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.shakingFields.removeAll()
        }
    }
}
