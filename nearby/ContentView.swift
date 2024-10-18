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
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(ColorManager.background)
            appearance.titleTextAttributes = [.font: UIFont.rounded(ofSize: 20, weight: .bold), .foregroundColor: UIColor(ColorManager.text)]
            appearance.largeTitleTextAttributes = [.font: UIFont.rounded(ofSize: 34, weight: .bold), .foregroundColor: UIColor(ColorManager.text)]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
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

extension UIFont {
    class func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let font: UIFont
        
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: descriptor, size: size)
        } else {
            font = systemFont
        }
        
        return font
    }
}

#Preview {
    ContentView()
}
