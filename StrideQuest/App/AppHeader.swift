import SwiftUI

struct AppHeader: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo/Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundStyle(.teal)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .onAppear {
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            isAnimating = true
                        }
                    }
            }
            
            // App Title
            VStack(alignment: .leading, spacing: 2) {
                Text("StrideQuest")
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                Text("Your Adventure Awaits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Stats or additional info could go here
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int.random(in: 1...10))K")
                    .font(.headline)
                    .foregroundStyle(.teal)
                Text("Steps Today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
