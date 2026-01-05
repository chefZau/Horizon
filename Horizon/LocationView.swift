//
//  LocationView.swift
//  Horizon
//
//  Created by Codex on 2026-01-03.
//

import SwiftUI

struct LocationView: View {
    @State private var city: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(city ?? "Current location")
                .font(.headline)

            Text("Uses your current device location automatically and shares it with the widget (read-only).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        let data = AppGroupStore.loadLocation()
        city = data.city ?? "Current location"
    }
}
