//
//  RouteFinishView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-12-23.
//
import SwiftUI

struct RouteCompletionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingRouteSelection = false

    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Congratulations!")
                .font(.system(.largeTitle, design: .default))
                .fontWeight(.bold)
            
            Text("You've completed this route!")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: {
                showingRouteSelection = true
            }) {
                Text("Next Route")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .sheet(isPresented: $showingRouteSelection) {
            RouteSelectionView()
        }
        .foregroundColor(.backgroundSq)
        .background(
            Image("sq-bg-2")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(contentMode: .fill)
                .offset(y: 30)
                .ignoresSafeArea()
        )
    }
}
