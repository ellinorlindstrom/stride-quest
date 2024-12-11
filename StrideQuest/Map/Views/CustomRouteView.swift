import SwiftUI
import MapKit

struct CustomRouteView: View {
    @ObservedObject var routeManager = CustomRouteManager.shared
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default center
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []

    var body: some View {
        VStack {
            // Search Bar
            HStack {
                TextField("Search for a location", text: $searchText, onCommit: {
                    searchForPlaces(query: searchText)
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                Button(action: {
                    searchForPlaces(query: searchText)
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }

            // Custom Map View
            CustomMapView(region: $mapRegion) { coordinate in
                addWaypoint(location: coordinate)
            }
            .edgesIgnoringSafeArea(.all)

            // Waypoint List and Save Button
            VStack {
                List(routeManager.waypoints) { waypoint in
                    Text("Lat: \(waypoint.coordinate.latitude), Lon: \(waypoint.coordinate.longitude)")
                }

                Button("Save Route") {
                    saveRoute()
                }
                .padding()
            }
        }
    }

    // Search for locations
    func searchForPlaces(query: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.region = mapRegion

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Error searching for places: \(String(describing: error))")
                return
            }

            self.searchResults = response.mapItems
        }
    }

    // Add waypoint
    func addWaypoint(location: CLLocationCoordinate2D) {
        routeManager.addWaypoint(location)
    }

    // Save the custom route
    func saveRoute() {
        let routeName = "Custom Route"
        let routeDescription = "Created by user"
        _ = routeManager.saveRoute(name: routeName, description: routeDescription)
        print("Route saved!")
    }
}
