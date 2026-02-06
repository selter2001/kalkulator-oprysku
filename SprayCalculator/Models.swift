import Foundation

// MARK: - Area Units
enum AreaUnit: String, CaseIterable, Codable {
    case hectares = "ha"
    case ares = "ar"
    case squareMeters = "m²"
    
    var toHectares: Double {
        switch self {
        case .hectares: return 1.0
        case .ares: return 0.01
        case .squareMeters: return 0.0001
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Spray Calculation Model
struct SprayCalculation: Identifiable, Codable {
    let id: UUID
    let date: Date
    let fieldArea: Double
    let areaUnit: AreaUnit
    let sprayRate: Double      // l/ha
    let chemicalRate: Double   // l/ha
    let tankCapacity: Double   // l
    
    // Computed results
    var fieldAreaInHectares: Double {
        fieldArea * areaUnit.toHectares
    }
    
    var totalWorkingFluid: Double {
        fieldAreaInHectares * sprayRate
    }
    
    var totalChemical: Double {
        fieldAreaInHectares * chemicalRate
    }
    
    var fullTanks: Int {
        Int(totalWorkingFluid / tankCapacity)
    }
    
    var partialTankVolume: Double {
        totalWorkingFluid.truncatingRemainder(dividingBy: tankCapacity)
    }
    
    var hasPartialTank: Bool {
        partialTankVolume > 0.01
    }
    
    var chemicalPerTank: Double {
        guard totalWorkingFluid > 0 else { return 0 }
        return (chemicalRate / sprayRate) * tankCapacity
    }
    
    var chemicalForPartialTank: Double {
        guard totalWorkingFluid > 0 else { return 0 }
        return (chemicalRate / sprayRate) * partialTankVolume
    }

    /// Litry wody do wlania do kazdego pelnego zbiornika
    var waterPerFullTank: Double {
        tankCapacity - chemicalPerTank
    }

    /// Litry wody do wlania do ostatniego niepelnego zbiornika
    var waterForPartialTank: Double {
        partialTankVolume - chemicalForPartialTank
    }
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        fieldArea: Double,
        areaUnit: AreaUnit = .hectares,
        sprayRate: Double,
        chemicalRate: Double,
        tankCapacity: Double
    ) {
        self.id = id
        self.date = date
        self.fieldArea = fieldArea
        self.areaUnit = areaUnit
        self.sprayRate = sprayRate
        self.chemicalRate = chemicalRate
        self.tankCapacity = tankCapacity
    }
}

// MARK: - Favorite Configuration
struct FavoriteConfiguration: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let dateCreated: Date
    let sprayRate: Double
    let chemicalRate: Double
    let tankCapacity: Double
    let areaUnit: AreaUnit
    
    init(
        id: UUID = UUID(),
        name: String,
        dateCreated: Date = Date(),
        sprayRate: Double,
        chemicalRate: Double,
        tankCapacity: Double,
        areaUnit: AreaUnit = .hectares
    ) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.sprayRate = sprayRate
        self.chemicalRate = chemicalRate
        self.tankCapacity = tankCapacity
        self.areaUnit = areaUnit
    }
}
