//
//  ContentView.swift
//  nearby
//
//  Created by Eric on 10/17/24.
//

import SwiftUI
import CoreLocation
import CoreLocationUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showGrid = false
    
    var body: some View {
        NavigationView {
            VStack {
                if showGrid {
                    if let location = locationManager.location {
                        NearbyPlacesGrid(location: location)
                    } else {
                        Text("location not available")
                    }
                } else {
                    LocationButton(.shareCurrentLocation) {
                        locationManager.requestLocation()
                    }
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .tint(.blue)
                    .padding()
                }
            }
            .navigationTitle("nearby")
            .navigationBarTitleDisplayMode(.inline)
        }
        .modifier(LocationUpdateModifier(locationUpdated: locationManager.locationUpdated, showGrid: $showGrid))
    }
}

// This modifier handles the location update for both iOS 17+ and earlier versions
struct LocationUpdateModifier: ViewModifier {
    let locationUpdated: Bool
    @Binding var showGrid: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: locationUpdated) { _, newValue in
                if newValue {
                    showGrid = true
                }
            }
        } else {
            content.onChange(of: locationUpdated) { newValue in
                if newValue {
                    showGrid = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
