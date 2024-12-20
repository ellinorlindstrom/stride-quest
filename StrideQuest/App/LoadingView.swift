import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            // Simple progress view with custom styling
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Loading...")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

//// Usage example in your MapView
//struct MapView: View {
//    @State private var isLoading = true
//    
//    var body: some View {
//        ZStack {
//            // Your existing map content here
//            
//            if isLoading {
//                SimpleLoadingView()
//                    .zIndex(100)
//            }
//        }
//    }
//}

// Preview
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}

#Preview {
    LoadingView()
}
