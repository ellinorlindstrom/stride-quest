import SwiftUI
import MapKit

struct CurrentPositionView: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.2))
                .frame(width: 40, height: 40)
            Circle()
                .fill(.blue)
                .frame(width: 15, height: 15)
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                }
        }
    }
}
