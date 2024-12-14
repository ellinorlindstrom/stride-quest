//import SwiftUI
//import MapKit
//
//struct RouteMapView: View {
//    @StateObject private var viewModel: RouteMapViewModel
//    
//    init(routeManager: RouteManager = .shared) {
//        _viewModel = StateObject(wrappedValue: RouteMapViewModel(routeManager: routeManager))
//    }
//    
//    var body: some View {
//        ZStack {
//            Map {
//                // Main route path
//                if let route = viewModel.currentRoute {
//                    MapPolyline(coordinates: route.fullPath)
//                        .stroke(.yellow, lineWidth: 3)
//                    
//                    // Progress overlay
//                    if let progress = viewModel.currentProgress {
//                        let completedCoordinates = progress.completedPath + [viewModel.currentPosition].compactMap { $0 }
//                        MapPolyline(coordinates: completedCoordinates)
//                            .stroke(.blue, lineWidth: 3)
//                    }
//                    
//                    // Milestones
//                    ForEach(route.milestones) { milestone in
//                        if let coordinate = route.coordinate(at: milestone.distanceFromStart) {
//                            Annotation(milestone.name, coordinate: coordinate) {
//                                MilestoneAnnotationView(
//                                    milestone: milestone,
//                                    coordinate: coordinate,
//                                    isCompleted: viewModel.isMilestoneCompleted(milestone),
//                                    onTap: {
//                                        viewModel.handleMilestoneSelected(milestone)
//                                    },
//                                    currentRouteId: route.id
//                                )
//                            }
//                        }
//                    }
//                    
//                    // Current position
//                    if let position = viewModel.currentPosition {
//                        Annotation("Current Position", coordinate: position) {
//                            CurrentPositionView(coordinate: position)
//                        }
//                    }
//                }
//            }
//            .mapStyle(.standard(elevation: .realistic))
//            .mapControls {
//                MapPitchToggle()
//                MapCompass()
//                MapScaleView()
//            }
//            
//            // Milestone detail card
//            if viewModel.showingMilestoneCard,
//               let selectedMilestone = viewModel.selectedMilestone,
//               let routeId = viewModel.currentRoute?.id {
//                MilestoneDetailCard(
//                    milestone: selectedMilestone,
//                    routeId: routeId,
//                    isShowing: $viewModel.showingMilestoneCard,
//                    selectedMilestone: $viewModel.selectedMilestone
//                )
//            }
//            
//            // Progress overlay
//            RouteProgressView()
//                .padding()
//        }
//        .onAppear {
//            viewModel.setInitialCamera()
//        }
//        .onChange(of: viewModel.currentProgress?.completedDistance) { oldValue, newValue in
//            viewModel.updateProgressPath()
//        }
//    }
//}
