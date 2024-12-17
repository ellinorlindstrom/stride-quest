import SwiftUI

struct MilestoneCard: View {
    @ObservedObject private var routeManager = RouteManager.shared
    let milestone: RouteMilestone
    let routeId: UUID
    @Binding var isShowing: Bool
    @Binding var selectedMilestone: RouteMilestone?
    @State private var shouldCompleteRoute = false
    
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
                    .font(.system(.title2, design: .monospaced))
                    .bold()
                    .padding(.vertical, 8)
                
                Text(milestone.description)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                // Add Complete Route button for final milestone
                if isFinalMilestone {
                    Button(action: {
                        shouldCompleteRoute = true
                        handleDismiss()
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
        // Use small epsilon for floating point comparison
        return abs(milestone.distanceFromStart - route.totalDistance) < 0.1
    }
    
    private func handleDismiss() {
        withAnimation {
            isShowing = false
            selectedMilestone = nil
            
            // If this is the final milestone and we should complete the route
            if isFinalMilestone && shouldCompleteRoute {
                if var progress = routeManager.currentProgress {
                    // Complete the route after card dismissal
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        progress.markCompleted()
                        routeManager.handleRouteCompletion(progress)
                    }
                }
            }
        }
    }
    
}

