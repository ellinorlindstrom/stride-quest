import SwiftUI

struct MilestoneDetailCard: View {
    let milestone: RouteMilestone
    @Binding var isShowing: Bool
    @Binding var selectedMilestone: RouteMilestone?
    
    var body: some View {
        VStack {
            // Header with close button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        isShowing = false
                        selectedMilestone = nil  
                    }
                    
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
            }
            .padding(.bottom, 4)
            
            // Milestone image
            Image(milestone.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(10)
            
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
    }
}

