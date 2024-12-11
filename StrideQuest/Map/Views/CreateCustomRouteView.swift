import SwiftUI
import MapKit

struct CustomRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var routeManager = CustomRouteManager.shared
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isShowingSearchResults = false
    
    var body: some View {
        ZStack {
            // Custom Map View
            CustomMapView(region: $mapRegion, waypoints: routeManager.waypoints) { coordinate in
                addWaypoint(location: coordinate)
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Search Bar
                HStack {
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                    
                    TextField("Search for a location", text: $searchText, onCommit: {
                        searchForPlaces(query: searchText)
                        isShowingSearchResults = true
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    Button(action: {
                        searchForPlaces(query: searchText)
                        isShowingSearchResults = true
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding()
                
                // Search Results
                if isShowingSearchResults && !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        Button(action: {
                            if let location = item.placemark.location?.coordinate {
                                addWaypoint(location: location)
                                mapRegion.center = location
                                isShowingSearchResults = false
                                searchText = ""
                            }
                        }) {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "Unknown Location")
                                if let address = item.placemark.title {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Save Button
                Button(action: {
                    saveRoute()
                    dismiss()
                }) {
                    Text("Save Route")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
        }
    }
    
    func searchForPlaces(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.region = mapRegion
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error searching for places: \(error.localizedDescription)")
                    return
                }
                
                if let response = response {
                    self.searchResults = response.mapItems
                } else {
                    self.searchResults = []
                }
            }
        }
    }
    
    func addWaypoint(location: CLLocationCoordinate2D) {
        routeManager.addWaypoint(location)
    }
    
    func saveRoute() {
        let routeName = "Custom Route"
        let routeDescription = "Created by user"
        _ = routeManager.saveRoute(name: routeName, description: routeDescription)
        print("Route saved!")
    }
}
