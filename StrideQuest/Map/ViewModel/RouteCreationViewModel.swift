////
////  RouteCreationViewModel.swift
////  StrideQuest
////
////  Created by Ellinor Lindström on 2024-12-14.
////
//import SwiftUI
//import MapKit
//
//@MainActor
//final class RouteCreationViewModel: ObservableObject {
//    @Published var searchText = ""
//    @Published var searchResults: [MKMapItem] = []
//    @Published var isShowingSearchResults = false
//    @Published var routeName = ""
//    @Published var routeDescription = ""
//    @Published var showingAlert = false
//    @Published private(set) var waypoints: [Waypoint] = []
//    @Published private(set) var routeSegments: [RouteSegment] = []
//    
//    private let routeManager: CustomRouteManager
//    private var mapRegion = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
//    )
//    
//    init(routeManager: CustomRouteManager) {
//        self.routeManager = routeManager
//    }
//    
//    func handleMapTap(_ coordinate: CLLocationCoordinate2D) {
//        routeManager.addWaypoint(coordinate)
//    }
//    
//    func searchForPlaces() {
//        guard !searchText.isEmpty else {
//            searchResults = []
//            return
//        }
//        
//        let request = MKLocalSearch.Request()
//        request.naturalLanguageQuery = searchText
//        request.region = mapRegion
//        
//        MKLocalSearch(request: request).start { [weak self] response, error in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("Search error: \(error.localizedDescription)")
//                    return
//                }
//                
//                self.searchResults = response?.mapItems ?? []
//                self.isShowingSearchResults = !self.searchResults.isEmpty
//            }
//        }
//    }
//    
//    func handleSearchResultSelection(_ item: MKMapItem) {
//        if let location = item.placemark.location?.coordinate {
//            routeManager.addWaypoint(location)
//            mapRegion.center = location
//            isShowingSearchResults = false
//            searchText = ""
//        }
//    }
//    
//    func saveAndStartRoute(completion: @escaping () -> Void) {
//        guard !waypoints.isEmpty else {
//            showingAlert = true
//            return
//        }
//        
//        let name = routeName.isEmpty ? "Custom Route" : routeName
//        let description = routeDescription.isEmpty ? "Created on \(Date().formatted())" : routeDescription
//        
//        _ = routeManager.saveRoute(name: name, description: description)
//        completion()
//    }
//}
