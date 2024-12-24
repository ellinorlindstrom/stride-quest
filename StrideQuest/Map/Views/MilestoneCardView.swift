import SwiftUI

struct MilestoneCard: View {
    @EnvironmentObject var routeManager: RouteManager
    let milestone: RouteMilestone
    let routeId: UUID
    @Binding var isShowing: Bool
    @Binding var selectedMilestone: RouteMilestone?
    
    var body: some View {
        if milestone.routeId == routeId {
            VStack {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: handleDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.title2)
                    }
                }
                .padding(.bottom, 4)
                
                // Milestone image
                if !milestone.imageName.isEmpty {
                    Image(milestone.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .cornerRadius(10)
                        .overlay(
                            Text("No Image")
                                .foregroundColor(.white)
                                .font(.caption)
                        )
                }
                
                
                
                // Milestone info
                Text(milestone.name)
                    .font(.system(.title2, design: .rounded))
                    .bold()
                    .padding(.vertical, 8)
                
                Text(milestone.description)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                if isFinalMilestone {
                    Button(action: {
                        completeRoute()
                    }) {
                        Text("Complete Route")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            .padding()
            .frame(width: 300, height: 450)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 10)
            )
            .transition(.scale.combined(with: .opacity))
            .offset(y: -50)
        } else {
            EmptyView()
        }
    }
    private var isFinalMilestone: Bool {
        guard let route = routeManager.getRoute(by: routeId) else { return false }
        return abs(milestone.distanceFromStart - route.totalDistance) < 0.1
    }
    
    private func completeRoute() {
        guard let currentProgress = routeManager.currentProgress else { return }
        
        // Create an updated progress with completion
        var updatedProgress = currentProgress
        updatedProgress.finalizeCompletion()
        
        // First save the updated progress
        routeManager.saveProgress()
        
        // Then handle route completion
        routeManager.handleRouteCompletion(updatedProgress)
        
        // Finally, dismiss the card
        withAnimation {
            isShowing = false
            selectedMilestone = nil
        }
    }
    
    private func handleDismiss() {
        // If it's the final milestone, complete the route before dismissing
        if isFinalMilestone {
            completeRoute()
        } else {
            // Otherwise just dismiss normally
            withAnimation {
                isShowing = false
                selectedMilestone = nil
            }
        }
    }
}
