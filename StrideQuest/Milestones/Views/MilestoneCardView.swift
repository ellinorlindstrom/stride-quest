import SwiftUI

struct MilestoneCard: View {
    @EnvironmentObject var routeManager: RouteManager
    let milestone: RouteMilestone
    let routeId: UUID
    @Binding var isShowing: Bool
    @Binding var selectedMilestone: RouteMilestone?
    @State private var showingRouteSelection: Bool = false
    @State private var isTruncated: Bool = false
    @State private var showingFullText: Bool = false
    @State private var showingCompletionView = false
    
    var body: some View {
        if milestone.routeId == routeId {
            VStack {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: {
                        print("Dismissing card")
                        showingCompletionView = false
                        showingFullText = false
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
                .zIndex(100)
                
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
                
                if checkIsFinalMilestone() {
                    Button(action: {
                        showingCompletionView = true
                    }) {
                        Text("Complete Route")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondSecondarySq)
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
                    .fill(.backgroundSq)
                    .shadow(radius: 10)
            )
            .transition(.scale.combined(with: .opacity))
            .offset(y: -50)
            .sheet(isPresented: $showingCompletionView) {
                RouteCompletionView ()
            }
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
    
    
    
    private func checkIsFinalMilestone() -> Bool {
        guard let route = routeManager.getRoute(by: routeId) else {
            print("⚠️ Could not find route with ID: \(routeId)")
            return false
        }
        let isFinal = abs(milestone.distanceFromStart - route.totalDistance) < 0.5
        print("🎯 Checking final milestone: distance = \(milestone.distanceFromStart), total = \(route.totalDistance), isFinal = \(isFinal)")
        return isFinal
    }
    
    
    
    //    private func handleDismiss() {
    //        if isFinalMilestone {
    //            showingCompletionView = true
    //            return
    //        }
    //
    //            withAnimation {
    //                isShowing = false
    //                selectedMilestone = nil
    //            }
    //        }
}


struct FullTextView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let text: String
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(title)
                            .font(.system(.title, design: .rounded))
                            .bold()
                            .foregroundColor(Color(.textSq))
                            .padding(.top, 20)
                        
                        Text(text)
                            .foregroundColor(Color(.textSq))
                            .zIndex(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                
                Image("sq-bg-2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea()
            }
            .frame(maxHeight: .infinity)
            .background(Color(.backgroundSq))
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

#Preview {
    FullTextView(
        title: "Sample Milestone",
        text: """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
        
        """
    )
}

