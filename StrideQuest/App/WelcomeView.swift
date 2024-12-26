import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var routeManager: RouteManager
    var onCompletion: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Welcome to")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(Color(.primarySq))
                
                Text("STRIDE QUEST")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.black)
                    .foregroundStyle(Color(.secondSecondarySq))
                
                VStack(spacing: 16) {
                    Text("Your Journey Begins Here!")
                        .font(.system(.headline, design: .default))
                        .fontWeight(.bold)
                        .foregroundStyle(Color(.primarySq))
                    
                    Text("Get ready to transform your daily walks into epic adventures. Each step brings you closer to completing amazing routes around the world.")
                        .font(.system(.callout, design: .default))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(.textSq))
                        .padding(.horizontal, 32)
                }
                .padding(.top, 20)
                
                Spacer()
                
                Button(action: {
                    routeManager.showingRouteSelection = true
                    onCompletion()
                }) {
                    Text("Start Your First Quest")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondSecondarySq))
                        .foregroundStyle(Color(.textSq))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 90)
            }
            .frame(maxHeight: .infinity)
            .background(
                Image("sq-bg-2")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(contentMode: .fill)
                    .offset(y: 30)
                    .ignoresSafeArea()
            )
        }
        .background(Color(.backgroundSq))
    }
}


