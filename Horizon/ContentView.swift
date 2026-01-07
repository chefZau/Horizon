//
//  ContentView.swift
//  Horizon
//
//  Created by Luca Zhou on 2026-01-03.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Today")) {
                    TodayView()
                }
                Section(header: Text("App Icon")) {
                    AppIconView()
                }
                Section(header: Text("Location")) {
                    LocationView()
                }
                Section(header: Text("About")) {
                    AboutView()
                }
#if DEBUG
                Section(header: Text("Debug")) {
                    DebugLocationView()
                }
#endif
            }
            .navigationTitle("Horizon")
        }
    }
}

#Preview {
    ContentView()
}
