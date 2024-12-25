import SwiftUI

struct MilestoneCard: View {
    @EnvironmentObject var routeManager: RouteManager
    let milestone: RouteMilestone
    let routeId: UUID
    @Binding var isShowing: Bool
    @Binding var selectedMilestone: RouteMilestone?
    
    @State private var isTruncated: Bool = false
    @State private var showingFullText: Bool = false
    
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
                    .lineLimit(4)
                    .background(
                        GeometryReader { geometry in
                            Color.clear.onAppear {
                                let frame = geometry.frame(in: .local)
                                let text = milestone.description as NSString
                                let textRect = text.boundingRect(
                                    with: CGSize(width: frame.width, height: .infinity),
                                    options: [.usesLineFragmentOrigin],
                                    attributes: [.font: UIFont.systemFont(ofSize: 17)],
                                    context: nil
                                )
                                isTruncated = textRect.height > frame.height
                            }
                        }
                    )
                
                if isTruncated {
                    Button(action: { showingFullText = true }) {
                        Text("Read More")
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                }
                
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
            .sheet(isPresented: $showingFullText) {
                           FullTextView(
                               title: milestone.name,
                               text: milestone.description
                           )
                       }
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
struct FullTextView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let text: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(text)
                        .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
