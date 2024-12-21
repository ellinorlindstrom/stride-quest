import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            // Simple progress view with custom styling
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.primarySq)
            

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// Preview
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}

#Preview {
    LoadingView()
}
