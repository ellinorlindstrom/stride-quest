import SwiftUI

struct MilestoneDetailCard: View {
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
                    Button(action: {
                        withAnimation {
                            print("🔘 Close button pressed")
                            print("🔘 isShowing before: \(isShowing)")
                            print("🔘 selectedMilestone before: \(String(describing: selectedMilestone))")
                            
                            isShowing = false
                            selectedMilestone = nil
                            
                            print("🔘 isShowing after: \(isShowing)")
                            print("🔘 selectedMilestone after: \(String(describing: selectedMilestone))")
                        }
                        
                    }) {
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
                    // Placeholder for when no image is available
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
            EmptyView() // Don't display anything if IDs don't match
        }
    }
    
}

