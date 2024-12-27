import SwiftUI

struct RouteCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var routeManager: RouteManager
    
    var body: some View {
        NavigationView {
            MainContent()
                .frame(maxHeight: .infinity)
                .background(Color(.backgroundSq))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            routeManager.completeRoute()
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Subviews
private extension RouteCompletionView {
    struct MainContent: View {
        @EnvironmentObject var routeManager: RouteManager
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            ZStack(alignment: .bottom) {
                ScrollableContent()
                BackgroundImage()
            }
        }
    }
    
    struct ScrollableContent: View {
        @EnvironmentObject var routeManager: RouteManager
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    HeaderText()
                    if let route = routeManager.currentRoute {
                        CompletionMessage(routeName: route.name)
                    }
                    ActionButton(dismiss: dismiss)
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
    }
    
    struct HeaderText: View {
        var body: some View {
            Text("Route Completed!")
                .font(.system(.title, design: .rounded))
                .bold()
                .foregroundColor(Color(.textSq))
                .padding(.top, 20)
                .multilineTextAlignment(.center)
        }
    }
    
    struct CompletionMessage: View {
        let routeName: String
        
        var body: some View {
            (Text("Congratulations! You've successfully completed ")
                .foregroundColor(Color(.textSq)) +
             Text(routeName)
                .bold()
                .foregroundColor(Color(.textSq)) +
             Text("! And unlocked a new route 🌍")
                .foregroundColor(Color(.textSq)))
            .zIndex(10)
            .padding(.top, 10)
            .multilineTextAlignment(.center)
        }
    }
    
    struct ActionButton: View {
        @EnvironmentObject var routeManager: RouteManager
        let dismiss: DismissAction
        
        var body: some View {
            VStack(spacing: 16) {
                Button(action: {
                    routeManager.completeRoute()
                    dismiss()
                    routeManager.showingRouteSelection = true
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
    }
    
    struct BackgroundImage: View {
        var body: some View {
            Image("sq-bg-2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}
