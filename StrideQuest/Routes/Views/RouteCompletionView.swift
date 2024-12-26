import SwiftUI


struct RouteCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var routeManager: RouteManager
    var onDismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Route Completed!")
                            .font(.system(.title, design: .rounded))
                            .bold()
                            .foregroundColor(Color(.textSq))
                            .padding(.top, 20)
                            .multilineTextAlignment(.center)
                        
                        if let route = routeManager.currentRoute {
                            Text("Congratulations! You've successfully completed \(route.name)!")
                                .foregroundColor(Color(.textSq))
                                .zIndex(10)
                                .padding(.top, 10)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 16) {
                            
                            Button(action: {
                                completeRoute()
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    routeManager.showingRouteSelection = true
                                }
                            }) {
                                Text("Start Next Route")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.secondSecondarySq))
                                    .foregroundColor(Color(.textSq))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                
                Image("sq-bg-2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
            }
            .frame(maxHeight: .infinity)
            .background(Color(.backgroundSq))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        completeRoute()
                    }
                }
            }
        }
    }
    private func completeRoute() {
        guard let currentProgress = routeManager.currentProgress else { return }
        var updatedProgress = currentProgress
        updatedProgress.finalizeCompletion()
        routeManager.saveProgress()
        routeManager.handleRouteCompletion(updatedProgress)
    }
}
