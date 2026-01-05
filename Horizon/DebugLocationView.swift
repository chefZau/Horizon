//
//  DebugLocationView.swift
//  Horizon
//
//  Created by Codex on 2026-01-03.
//

import SwiftUI
import Combine
import WidgetKit

struct DebugLocationView: View {
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var timestamp: Double?
    @State private var timeZoneId: String?
    @State private var message: String?

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f
    }()

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("lat: \(formatted(lat: latitude))")
            Text("lon: \(formatted(lon: longitude))")
            Text("tz: \(timeZoneId ?? "nil")")
            Text("ts: \(formatted(dateFrom: timestamp))")

            HStack {
                Button("Clear App Group Location") {
                    clear()
                }
                Button("Force Widget Refresh") {
                    WidgetCenter.shared.reloadAllTimelines()
                    message = "Reloaded timelines"
                }
            }
            .font(.caption)

            if let message {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(.caption, design: .monospaced))
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onAppear { refresh() }
        .onReceive(timer) { _ in refresh() }
    }

    private func refresh() {
        guard let defaults = UserDefaults(suiteName: AppGroup.id) else { return }
        latitude = defaults.object(forKey: "latitude") as? Double
        longitude = defaults.object(forKey: "longitude") as? Double
        timestamp = defaults.object(forKey: "timestamp") as? Double
        timeZoneId = defaults.string(forKey: "timeZoneId")
    }

    private func clear() {
        guard let defaults = UserDefaults(suiteName: AppGroup.id) else { return }
        defaults.removeObject(forKey: "latitude")
        defaults.removeObject(forKey: "longitude")
        defaults.removeObject(forKey: "timestamp")
        defaults.removeObject(forKey: "timeZoneId")
        defaults.synchronize()
        refresh()
        message = "Cleared stored location"
    }

    private func formatted(lat: Double?) -> String {
        guard let lat else { return "nil" }
        return String(format: "%.5f", lat)
    }

    private func formatted(lon: Double?) -> String {
        guard let lon else { return "nil" }
        return String(format: "%.5f", lon)
    }

    private func formatted(dateFrom timestamp: Double?) -> String {
        guard let ts = timestamp, ts > 0 else { return "nil" }
        return formatter.string(from: Date(timeIntervalSince1970: ts))
    }
}
