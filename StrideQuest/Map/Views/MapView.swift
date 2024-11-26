import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var plannedRoute: [CLLocationCoordinate2D]
    @Binding var progressRoute: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        
        let plannedPolyline = MKPolyline(coordinates: plannedRoute, count: plannedRoute.count)
        mapView.addOverlay(plannedPolyline)
        
        let progressPolyline = MKPolyline(coordinates: progressRoute, count: progressRoute.count)
        mapView.addOverlay(progressPolyline)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 4

            if overlay is MKPolyline {
                renderer.strokeColor = .gray
            } else {
                renderer.strokeColor = .blue
            }

            return renderer
        }
    }
}
