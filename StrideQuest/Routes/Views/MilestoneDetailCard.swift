import SwiftUI

struct MilestoneDetailCard: View {
    let milestone: RouteMilestone
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            // Header with close button
            HStack {
                Spacer()
                Button(action: { isShowing = false }) {
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

// Preview helper to simulate @Binding
struct MilestoneDetailCard_Previews: PreviewProvider {
    static var sampleMilestone = RouteMilestone(
        id: UUID(),
        name: "Mount Everest",
        description: "The highest peak on Earth, standing at 29,029 feet (8,848 meters) above sea level.",
        distanceFromStart: 800,
        imageName: "everest" // Make sure this image exists in your assets
       // distance: 8848,
        //isCompleted: false
    )
    
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3) // Background to see the card better
                .ignoresSafeArea()
            
            MilestoneDetailCard(
                milestone: sampleMilestone,
                isShowing: .constant(true)
            )
        }
    }
}
