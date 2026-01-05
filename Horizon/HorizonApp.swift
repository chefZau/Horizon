//
//  HorizonApp.swift
//  Horizon
//
//  Created by Luca Zhou on 2026-01-03.
//

import SwiftUI

@main
struct HorizonApp: App {
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    locationManager.start()
                }
        }
    }
}
