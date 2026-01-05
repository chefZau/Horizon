//
//  LocationView.swift
//  Horizon
//
//  Created by Codex on 2026-01-03.
//

import SwiftUI
import WidgetKit

struct LocationView: View {
    @State private var city: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(city ?? "Current location")
                    .font(.headline)
            }

            Text("Location is read from the main app (App Group) and shared with the widget.")
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
