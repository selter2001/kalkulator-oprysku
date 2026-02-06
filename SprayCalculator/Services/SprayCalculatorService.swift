import Foundation

struct SprayCalculatorService {
    func calculate(
        fieldArea: Double,
        areaUnit: AreaUnit,
        sprayRate: Double,
        chemicalRate: Double,
        tankCapacity: Double
    ) -> SprayCalculation {
        SprayCalculation(
            fieldArea: fieldArea,
            areaUnit: areaUnit,
            sprayRate: sprayRate,
            chemicalRate: chemicalRate,
            tankCapacity: tankCapacity
        )
    }
}
