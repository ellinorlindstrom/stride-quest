import SwiftUI
import MapKit

import SwiftUI
import MapKit

struct RouteCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var routeManager = CustomRouteManager.shared
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isShowingSearchResults = false
    @State private var routeSegments: [RouteSegment] = []
    @State private var routeName: String = ""
    @State private var routeDescription: String = ""
    @State private var showingAlert = false
    @State private var searchTask: DispatchWorkItem?
    
    private struct CustomSearchFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private struct CustomRouteFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                      to: nil,
                                      from: nil,
                                      for: nil)
    }
    
    var body: some View {
        ZStack {
            CustomMapView(region: $mapRegion,
                          waypoints: routeManager.waypoints,
                          segments: routeSegments) { coordinate in
                addWaypoint(location: coordinate)
            }
                          .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Search Bar and Results Container
                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrowshape.left.fill")
                                .foregroundColor(.gray)
                                .imageScale(.large)
                        }
                        .padding(.leading)
                        
                        TextField("Search for a location", text: $searchText)
                            .textFieldStyle(CustomSearchFieldStyle())
                            .onChange(of: searchText) { oldValue, newValue in
                                searchTask?.cancel()
                                
                                if newValue.count >= 2 {
                                    let task = DispatchWorkItem {
                                        searchForPlaces(query: newValue)
                                        isShowingSearchResults = true
                                    }
                                    searchTask = task
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
                                } else {
                                    searchResults = []
                                    isShowingSearchResults = false
                                }
                            }
                        
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .imageScale(.large)
                        }
                        .padding(.trailing)
                    }
                    .padding(.vertical, 12)
                    
                    // Search Results
                    if isShowingSearchResults && !searchResults.isEmpty {
                        List(searchResults, id: \.self) { item in
                            Button(action: {
                                if let location = item.placemark.location?.coordinate {
                                    dismissKeyboard()
                                    mapRegion.center = location
                                    isShowingSearchResults = false
                                    searchText = ""
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Unknown Location")
                                        .foregroundColor(.primary)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .frame(maxHeight: 250)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal)
                .padding(.top)
                
                Spacer()
                
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        TextField("Route Name", text: $routeName)
                            .textFieldStyle(CustomRouteFieldStyle())
                        
                        TextField("Route Description", text: $routeDescription)
                            .textFieldStyle(CustomRouteFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        if !routeManager.waypoints.isEmpty {
                            saveAndStartRoute()
                        } else {
                            showingAlert = true
                        }
                    }) {
                        Text("Save and Start Route")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -4)
                )
            }
        }
        .alert("No Waypoints", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please add at least one waypoint to create a route.")
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
        calculateRouteSegments()
    }
    
    func calculateRouteSegments() {
        guard routeManager.waypoints.count >= 2 else {
            routeSegments = []
            return
        }
        
        let waypoints = routeManager.waypoints
        var newSegments: [RouteSegment] = []
        let group = DispatchGroup()
        
        // Only calculate segments between consecutive waypoints
        for i in 0..<(waypoints.count - 1) {
            group.enter()
            calculateSegment(
                from: waypoints[i].coordinate,
                to: waypoints[i + 1].coordinate
            ) { segment in
                if let segment = segment {
                    DispatchQueue.main.async {
                        newSegments.append(segment)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Sort segments to ensure they're in the correct order
            self.routeSegments = newSegments.enumerated().sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    func calculateSegment(from source: CLLocationCoordinate2D,
                          to destination: CLLocationCoordinate2D,
                          completion: @escaping (RouteSegment?) -> Void) {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destPlacemark = MKPlacemark(coordinate: destination)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destPlacemark)
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                completion(nil)
                return
            }
            
            let points = route.polyline.points()
            let coords = (0..<route.polyline.pointCount).map { i in
                points[i].coordinate
            }
            
            let segment = RouteSegment(coordinates: coords)
            completion(segment)
        }
    }
    
    private func saveAndStartRoute() {
        let name = routeName.isEmpty ? "Custom Route" : routeName
        let description = routeDescription.isEmpty ? "Created on \(Date().formatted())" : routeDescription
        
        // Update the route segments in CustomRouteManager
        routeManager.routeSegments = routeSegments
        // Save the route
        _ = routeManager.saveRoute(
            name: name,
            description: description
        )
        
        dismiss()
    }
    
    func calculateTotalDistance() -> Double {
        var totalDistance: CLLocationDistance = 0
        
        for segment in routeSegments {
            let coordinates = segment.path
            for i in 0..<(coordinates.count - 1) {
                let location1 = CLLocation(latitude: coordinates[i].latitude,
                                           longitude: coordinates[i].longitude)
                let location2 = CLLocation(latitude: coordinates[i + 1].latitude,
                                           longitude: coordinates[i + 1].longitude)
                totalDistance += location1.distance(from: location2)
            }
        }
        
        return totalDistance
    }
}
