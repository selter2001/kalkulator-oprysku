import SwiftUI

// MARK: - Tractor Spraying Animation View
struct TractorSprayingAnimation: View {
    @State private var tractorOffset: CGFloat = -200
    @State private var isAnimating = false
    @State private var sprayDrops: [SprayDrop] = []
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { }
            
            VStack(spacing: 20) {
                // Animation container
                ZStack {
                    // Ground line
                    Rectangle()
                        .fill(LinearGradient.earthGradient)
                        .frame(height: 20)
                        .offset(y: 60)
                    
                    // Spray drops
                    ForEach(sprayDrops) { drop in
                        SprayDropView(drop: drop)
                    }
                    
                    // Tractor with sprayer
                    TractorView()
                        .offset(x: tractorOffset, y: 0)
                }
                .frame(height: 180)
                .clipped()
                
                // Loading text
                Text(isAnimating ? "Obliczanie..." : "")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.backgroundCard)
                    .shadow(radius: 20)
            )
            .padding(40)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        isAnimating = true
        
        // Start tractor movement
        withAnimation(.easeInOut(duration: 2.0)) {
            tractorOffset = 200
        }
        
        // Generate spray drops
        for i in 0..<30 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                if isAnimating {
                    addSprayDrop()
                }
            }
        }
        
        // Complete animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            isAnimating = false
            onComplete()
        }
    }
    
    private func addSprayDrop() {
        let drop = SprayDrop(
            id: UUID(),
            x: tractorOffset + CGFloat.random(in: -30...30),
            startY: 20,
            endY: CGFloat.random(in: 40...55)
        )
        sprayDrops.append(drop)
        
        // Remove drop after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            sprayDrops.removeAll { $0.id == drop.id }
        }
    }
}

// MARK: - Spray Drop Model
struct SprayDrop: Identifiable {
    let id: UUID
    let x: CGFloat
    let startY: CGFloat
    let endY: CGFloat
}

// MARK: - Spray Drop View
struct SprayDropView: View {
    let drop: SprayDrop
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.waterBlue.opacity(0.8))
            .frame(width: 6, height: 6)
            .offset(x: drop.x, y: isAnimating ? drop.endY : drop.startY)
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: 0.6)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Tractor View (Custom drawn)
struct TractorView: View {
    @State private var wheelRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Sprayer tank (behind tractor)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primaryGreen)
                .frame(width: 60, height: 35)
                .offset(x: -50, y: 10)
            
            // Spray boom
            Rectangle()
                .fill(Color.gray)
                .frame(width: 80, height: 4)
                .offset(x: -50, y: 30)
            
            // Spray nozzles
            ForEach(0..<5) { i in
                SprayNozzle()
                    .offset(x: -90 + CGFloat(i * 20), y: 35)
            }
            
            // Tractor body
            ZStack {
                // Hood
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primaryGreen)
                    .frame(width: 45, height: 30)
                    .offset(x: 20, y: 5)
                
                // Cabin
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.darkGreen)
                        .frame(width: 35, height: 40)
                    
                    // Window
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.waterBlue.opacity(0.5))
                        .frame(width: 25, height: 20)
                        .offset(y: -5)
                }
                .offset(x: -10, y: -5)
                
                // Exhaust pipe
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 15)
                    .offset(x: 35, y: -18)
                
                // Front wheel
                WheelView(size: 25)
                    .rotationEffect(.degrees(wheelRotation))
                    .offset(x: 30, y: 32)
                
                // Rear wheel (bigger)
                WheelView(size: 40)
                    .rotationEffect(.degrees(wheelRotation))
                    .offset(x: -20, y: 25)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                wheelRotation = 360
            }
        }
    }
}

// MARK: - Wheel View
struct WheelView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Tire
            Circle()
                .fill(Color.darkBrown)
                .frame(width: size, height: size)
            
            // Rim
            Circle()
                .fill(Color.gray)
                .frame(width: size * 0.5, height: size * 0.5)
            
            // Spokes
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: 2, height: size * 0.4)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            
            // Center hub
            Circle()
                .fill(Color.accentGold)
                .frame(width: size * 0.2, height: size * 0.2)
        }
    }
}

// MARK: - Spray Nozzle
struct SprayNozzle: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray)
                .frame(width: 4, height: 8)
            
            Triangle()
                .fill(Color.waterBlue.opacity(0.4))
                .frame(width: 12, height: 15)
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
#Preview {
    TractorSprayingAnimation(onComplete: {})
}
