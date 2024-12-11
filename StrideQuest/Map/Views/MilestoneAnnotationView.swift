import SwiftUI
import MapKit

struct MilestoneAnnotationView: View {
    let milestone: RouteMilestone
    let coordinate: CLLocationCoordinate2D
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .foregroundStyle(isCompleted ? .green : .gray)
            .font(.title)
            .onTapGesture(perform: onTap)
    }
}
