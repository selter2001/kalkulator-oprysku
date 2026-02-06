import SwiftUI
import Observation

enum Language: String, CaseIterable {
    case polish = "pl"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .polish: return "Polski"
        case .english: return "English"
        }
    }
    
    var flag: String {
        switch self {
        case .polish: return "🇵🇱"
        case .english: return "🇬🇧"
        }
    }
}

@Observable
class LocalizationManager {
    var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "pl"
        self.currentLanguage = Language(rawValue: saved) ?? .polish
    }
    
    // MARK: - Labels
    var appTitle: String {
        currentLanguage == .polish ? "Kalkulator Oprysku" : "Spray Calculator"
    }
    
    var fieldArea: String {
        currentLanguage == .polish ? "Powierzchnia pola" : "Field area"
    }
    
    var fieldAreaUnit: String { "ha" }
    
    var sprayRate: String {
        currentLanguage == .polish ? "Dawka cieczy" : "Spray rate"
    }
    
    var sprayRateUnit: String { "l/ha" }
    
    var chemicalRate: String {
        currentLanguage == .polish ? "Dawka środka" : "Chemical rate"
    }
    
    var chemicalRateUnit: String { "l/ha" }
    
    var tankCapacity: String {
        currentLanguage == .polish ? "Pojemność opryskiwacza" : "Tank capacity"
    }
    
    var tankCapacityUnit: String { "l" }
    
    var calculate: String {
        currentLanguage == .polish ? "Oblicz" : "Calculate"
    }
    
    var results: String {
        currentLanguage == .polish ? "Wyniki" : "Results"
    }
    
    var workingFluid: String {
        currentLanguage == .polish ? "Ciecz robocza" : "Working fluid"
    }
    
    var chemical: String {
        currentLanguage == .polish ? "Środek" : "Chemical"
    }
    
    var tankFills: String {
        currentLanguage == .polish ? "Napełnienia opryskiwacza" : "Tank fills"
    }
    
    var fullTanks: String {
        currentLanguage == .polish ? "pełne" : "full"
    }
    
    var partialTank: String {
        currentLanguage == .polish ? "częściowe" : "partial"
    }
    
    var liters: String { "l" }
    
    var history: String {
        currentLanguage == .polish ? "Historia" : "History"
    }
    
    var favorites: String {
        currentLanguage == .polish ? "Ulubione" : "Favorites"
    }
    
    var settings: String {
        currentLanguage == .polish ? "Ustawienia" : "Settings"
    }
    
    var language: String {
        currentLanguage == .polish ? "Język" : "Language"
    }
    
    var clear: String {
        currentLanguage == .polish ? "Wyczyść" : "Clear"
    }
    
    var save: String {
        currentLanguage == .polish ? "Zapisz" : "Save"
    }
    
    var saveToFavorites: String {
        currentLanguage == .polish ? "Zapisz do ulubionych" : "Save to favorites"
    }
    
    var configurationName: String {
        currentLanguage == .polish ? "Nazwa konfiguracji" : "Configuration name"
    }
    
    var cancel: String {
        currentLanguage == .polish ? "Anuluj" : "Cancel"
    }
    
    var delete: String {
        currentLanguage == .polish ? "Usuń" : "Delete"
    }
    
    var noHistory: String {
        currentLanguage == .polish ? "Brak historii obliczeń" : "No calculation history"
    }
    
    var noFavorites: String {
        currentLanguage == .polish ? "Brak zapisanych konfiguracji" : "No saved configurations"
    }
    
    var use: String {
        currentLanguage == .polish ? "Użyj" : "Use"
    }
    
    var emptyFieldError: String {
        currentLanguage == .polish ? "Uzupełnij wszystkie pola" : "Fill in all fields"
    }
    
    var invalidValueError: String {
        currentLanguage == .polish ? "Wprowadź poprawne wartości" : "Enter valid values"
    }
    
    var units: String {
        currentLanguage == .polish ? "Jednostki" : "Units"
    }
    
    var areaUnitLabel: String {
        currentLanguage == .polish ? "Jednostka powierzchni" : "Area unit"
    }

    // MARK: - Settings
    var version: String {
        currentLanguage == .polish ? "Wersja" : "Version"
    }

    var information: String {
        currentLanguage == .polish ? "Informacje" : "Information"
    }

    // MARK: - Animation
    var calculating: String {
        currentLanguage == .polish ? "Obliczanie..." : "Calculating..."
    }

    // MARK: - Per-tank composition (CALC-01, CALC-02, CALC-03)
    var fullTankComposition: String {
        currentLanguage == .polish ? "Skład pełnego zbiornika" : "Full tank composition"
    }

    var partialTankComposition: String {
        currentLanguage == .polish ? "Skład niepełnego zbiornika" : "Partial tank composition"
    }

    var water: String {
        currentLanguage == .polish ? "Woda" : "Water"
    }

    var totalChemicalToBuy: String {
        currentLanguage == .polish ? "Środek do kupienia" : "Chemical to buy"
    }

    // MARK: - Export & About (EXP-01, EXP-02)
    var exportPDF: String {
        currentLanguage == .polish ? "Eksportuj PDF" : "Export PDF"
    }

    var about: String {
        currentLanguage == .polish ? "O aplikacji" : "About"
    }

    var author: String {
        currentLanguage == .polish ? "Autor" : "Author"
    }

    var contact: String {
        currentLanguage == .polish ? "Kontakt" : "Contact"
    }

    var pdfSignature: String {
        currentLanguage == .polish ? "Wygenerowano w aplikacji autorstwa Wojciecha Olszaka" : "Generated in app by Wojciech Olszak"
    }

    var parameters: String {
        currentLanguage == .polish ? "Parametry" : "Parameters"
    }
}
