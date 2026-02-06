import SwiftUI

/// A print-only SwiftUI view for PDF rendering via ImageRenderer.
/// CRITICAL: Uses ONLY Color.black and Color.white -- never Asset Catalog colors.
/// Asset Catalog colors resolve to dark-mode variants and produce unreadable PDFs.
struct PDFContentView: View {
    let calculation: SprayCalculation
    let localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text(localization.appTitle)
                .font(.title.bold())

            Divider()

            // Date
            Text(calculation.date.formatted(date: .long, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(Color.gray)

            // Parameters section
            Text(localization.parameters)
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text(localization.fieldArea)
                    Text("\(formatNumber(calculation.fieldArea)) \(calculation.areaUnit.displayName)")
                        .bold()
                }
                GridRow {
                    Text(localization.sprayRate)
                    Text("\(formatNumber(calculation.sprayRate)) l/ha")
                        .bold()
                }
                GridRow {
                    Text(localization.chemicalRate)
                    Text("\(formatNumber(calculation.chemicalRate)) l/ha")
                        .bold()
                }
                GridRow {
                    Text(localization.tankCapacity)
                    Text("\(formatNumber(calculation.tankCapacity)) l")
                        .bold()
                }
            }

            Divider()

            // Results section
            Text(localization.results)
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text(localization.workingFluid)
                    Text("\(formatNumber(calculation.totalWorkingFluid)) l")
                        .bold()
                }
                GridRow {
                    Text(localization.totalChemicalToBuy)
                    Text("\(formatNumber(calculation.totalChemical)) l")
                        .bold()
                }
                GridRow {
                    Text(localization.tankFills)
                    Text(tankDescription)
                        .bold()
                }
            }

            Divider()

            // Full tank composition
            Text(localization.fullTankComposition)
                .font(.headline)
            Text("\(localization.water): \(formatNumber(calculation.waterPerFullTank)) l + \(localization.chemical): \(formatNumber(calculation.chemicalPerTank)) l")

            // Partial tank composition (conditional)
            if calculation.hasPartialTank {
                Text(localization.partialTankComposition)
                    .font(.headline)
                Text("\(localization.water): \(formatNumber(calculation.waterForPartialTank)) l + \(localization.chemical): \(formatNumber(calculation.chemicalForPartialTank)) l")
            }

            Spacer()

            Divider()

            // Footer signature
            Text(localization.pdfSignature)
                .font(.caption)
                .foregroundStyle(Color.gray)
        }
        .padding(40)
        .foregroundStyle(Color.black) // Always black text for PDF
        .background(Color.white)      // Always white background for PDF
    }

    // MARK: - Helpers

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var tankDescription: String {
        if calculation.fullTanks > 0 && calculation.hasPartialTank {
            return "\(calculation.fullTanks) \(localization.fullTanks) + 1 \(localization.partialTank)"
        } else if calculation.fullTanks > 0 {
            return "\(calculation.fullTanks) \(localization.fullTanks)"
        } else if calculation.hasPartialTank {
            return "1 \(localization.partialTank)"
        }
        return "0"
    }
}
