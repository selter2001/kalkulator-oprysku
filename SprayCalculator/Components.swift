import SwiftUI

// MARK: - Custom Input Field
struct SprayInputField: View {
    let title: String
    let unit: String
    @Binding var value: String
    let icon: String
    var isShaking: Bool = false

    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var verticalPadding: CGFloat = 14
    @ScaledMetric(relativeTo: .caption) private var unitPaddingH: CGFloat = 10
    @ScaledMetric(relativeTo: .caption) private var unitPaddingV: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color(.textSecondary))

            // Input container
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isFocused ? Color(.primaryGreen) : Color(.textSecondary))
                    .frame(width: iconWidth)

                // Text field
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .font(.body.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color(.textPrimary))
                    .focused($isFocused)

                // Unit label
                Text(unit)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(.textSecondary))
                    .padding(.horizontal, unitPaddingH)
                    .padding(.vertical, unitPaddingV)
                    .background(
                        Capsule()
                            .fill(Color(.backgroundSecondary))
                    )
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.backgroundCard))
                    .shadow(color: isFocused ? Color(.primaryGreen).opacity(0.2) : Color(.textPrimary).opacity(0.05),
                            radius: isFocused ? 8 : 4,
                            x: 0,
                            y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? Color(.primaryGreen) : Color.clear, lineWidth: 2)
            )
            .offset(x: isShaking ? -10 : 0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
    }
}

// MARK: - Result Card
struct ResultCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    var detail: String? = nil
    var delay: Double = 0

    @State private var isVisible = false
    @ScaledMetric(relativeTo: .title2) private var iconCircleSize: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 16

    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(AppGradients.primaryGradient)
                    .frame(width: iconCircleSize, height: iconCircleSize)

                Text(icon)
                    .font(.title3)
            }
            .scaleEffect(isVisible ? 1 : 0.5)
            .opacity(isVisible ? 1 : 0)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color(.textSecondary))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color(.textPrimary))
                        .contentTransition(.numericText())

                    Text(unit)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(.textSecondary))
                }

                if let detail = detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color(.primaryGreen))
                        .fontWeight(.medium)
                }
            }
            .offset(x: isVisible ? 0 : 20)
            .opacity(isVisible ? 1 : 0)

            Spacer()
        }
        .padding(cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.backgroundCard))
                .shadow(color: Color(.textPrimary).opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var isLoading: Bool = false

    @State private var isPressed = false
    @ScaledMetric(relativeTo: .body) private var verticalPadding: CGFloat = 18

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }

                Text(title)
                    .font(.body.weight(.bold))
                    .fontDesign(.rounded)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppGradients.primaryGradient)
                    .shadow(color: Color(.primaryGreen).opacity(0.4), radius: isPressed ? 4 : 12, x: 0, y: isPressed ? 2 : 6)
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
            }
            .foregroundStyle(Color(.primaryGreen))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .stroke(Color(.primaryGreen), lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(.primaryGreen))

            Text(title)
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(Color(.textPrimary))

            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
