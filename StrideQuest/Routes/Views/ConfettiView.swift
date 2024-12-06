import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var rotation: Double
    var scale: Double
}

struct ConfettiView: View {
    @Binding var isShowing: Bool
    @State private var particles: [ConfettiParticle] = []
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Rectangle()
                    .fill(particle.color)
                    .frame(width: 8, height: 8)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))
                    .scaleEffect(particle.scale)
            }
        }
        .onChange(of: isShowing) {
            if isShowing {
                createConfetti()
            }
        }
    }
    
    private func createConfetti() {
        particles = []
        
        // Create 100 particles
        for _ in 0..<100 {
            let randomX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            let particle = ConfettiParticle(
                position: CGPoint(x: randomX, y: -20),
                color: colors.randomElement() ?? .blue,
                rotation: Double.random(in: 0...360),
                scale: Double.random(in: 0.7...1.3)
            )
            particles.append(particle)
        }
        
        // Animate particles
        withAnimation(
            Animation
                .linear(duration: 3)
                .repeatCount(1, autoreverses: false)
        ) {
            for i in particles.indices {
                let randomX = CGFloat.random(in: -50...50)
                let finalY = UIScreen.main.bounds.height + 20
                particles[i].position = CGPoint(
                    x: particles[i].position.x + randomX,
                    y: finalY
                )
                particles[i].rotation += Double.random(in: 180...360)
            }
        }
        
        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isShowing = false
            particles = []
        }
    }
}
