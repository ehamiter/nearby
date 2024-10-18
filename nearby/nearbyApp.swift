//
//  nearbyApp.swift
//  nearby
//
//  Created by Eric on 10/17/24.
//

import SwiftUI

@main
struct NearbyApp: App {
    init() {
        Self.setupURLCache()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private static func setupURLCache() {
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 100 * 1024 * 1024 // 100 MB
        let urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "nearby_image_cache")
        URLCache.shared = urlCache
    }
}
