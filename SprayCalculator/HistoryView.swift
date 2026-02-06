import SwiftUI

struct HistoryView: View {
    @Environment(LocalizationManager.self) private var localization
    @Environment(HistoryManager.self) private var historyManager

    var body: some View {
        Group {
            if historyManager.calculations.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .background(AppGradients.backgroundGradient.ignoresSafeArea())
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(Color(.textSecondary).opacity(0.5))

            Text(localization.noHistory)
                .font(.headline)
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - History List
    private var historyList: some View {
        List {
            ForEach(historyManager.calculations) { calculation in
                HistoryRowView(calculation: calculation)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete(perform: historyManager.deleteCalculation)
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    withAnimation {
                        historyManager.clearHistory()
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color(.errorRed))
                }
            }
        }
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    @Environment(LocalizationManager.self) private var localization
    let calculation: SprayCalculation
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(calculation.date))
                        .font(.caption)
                        .foregroundStyle(Color(.textSecondary))

                    Text("\(formatNumber(calculation.fieldArea)) \(calculation.areaUnit.displayName)")
                        .font(.headline)
                        .foregroundStyle(Color(.textPrimary))
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color(.textSecondary))
            }

            // Expanded details
            if isExpanded {
                VStack(spacing: 8) {
                    DetailRow(icon: "💧", label: localization.workingFluid, value: "\(formatNumber(calculation.totalWorkingFluid)) l")
                    DetailRow(icon: "🧪", label: localization.chemical, value: "\(formatNumber(calculation.totalChemical)) l")
                    DetailRow(icon: "🚜", label: localization.tankFills, value: tankFillsText)
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.backgroundCard))
                .shadow(color: Color(.textPrimary).opacity(0.05), radius: 5, y: 2)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }
    }

    private var tankFillsText: String {
        if calculation.hasPartialTank {
            return "\(calculation.fullTanks) \(localization.fullTanks) + 1 \(localization.partialTank) (\(formatNumber(calculation.partialTankVolume)) l)"
        }
        return "\(calculation.fullTanks) \(localization.fullTanks)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(icon)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color(.textSecondary))
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color(.textPrimary))
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(LocalizationManager())
            .environment(HistoryManager())
    }
}
