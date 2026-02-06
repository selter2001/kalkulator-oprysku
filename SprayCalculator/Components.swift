import SwiftUI

// MARK: - Custom Input Field
struct SprayInputField: View {
    let title: String
    let unit: String
    @Binding var value: String
    let icon: String
    var isShaking: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
            
            // Input container
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isFocused ? .primaryGreen : .textSecondary)
                    .frame(width: 24)
                
                // Text field
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .focused($isFocused)
                
                // Unit label
                Text(unit)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.backgroundLight)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.backgroundCard)
                    .shadow(color: isFocused ? Color.primaryGreen.opacity(0.2) : Color.black.opacity(0.05),
                            radius: isFocused ? 8 : 4,
                            x: 0,
                            y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? Color.primaryGreen : Color.clear, lineWidth: 2)
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 50, height: 50)
                
                Text(icon)
                    .font(.system(size: 24))
            }
            .scaleEffect(isVisible ? 1 : 0.5)
            .opacity(isVisible ? 1 : 0)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .contentTransition(.numericText())
                    
                    Text(unit)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                }
                
                if let detail = detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.primaryGreen)
                        .fontWeight(.medium)
                }
            }
            .offset(x: isVisible ? 0 : 20)
            .opacity(isVisible ? 1 : 0)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.backgroundCard)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
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
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient.primaryGradient)
                    .shadow(color: Color.primaryGreen.opacity(0.4), radius: isPressed ? 4 : 12, x: 0, y: isPressed ? 2 : 6)
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
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.primaryGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .stroke(Color.primaryGreen, lineWidth: 1.5)
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryGreen)
            
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
