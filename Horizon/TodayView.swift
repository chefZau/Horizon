//
//  TodayView.swift
//  Horizon
//
//  Created by Codex on 2026-01-03.
//

import SwiftUI

struct TodayView: View {
    @State private var summary: TodaySummary = TodaySummary.placeholder()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(summary.phaseTitle)
                .font(.headline)
            Text("Next change in \(summary.countdown)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading) {
                    Text("Sunrise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.sunrise)
                        .font(.body)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Sunset")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.sunset)
                        .font(.body)
                }
            }
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        summary = TodaySummary.compute()
    }
}

struct TodaySummary {
    let phaseTitle: String
    let sunrise: String
    let sunset: String
    let countdown: String

    static func placeholder() -> TodaySummary {
        TodaySummary(phaseTitle: "Sunrise", sunrise: "--:--", sunset: "--:--", countdown: "--")
    }

    static func compute() -> TodaySummary {
        let data = AppGroupStore.loadLocation()
        let coords = Coordinates(latitude: data.latitude, longitude: data.longitude)
        let tz = data.timeZone
        let now = Date()

        let state = SunDataService.computeSunState(now: now, coords: coords, tz: tz)

        #if DEBUG
        let iso = ISO8601DateFormatter()
        iso.timeZone = tz
        let sunriseIso = state.sunrise.map { iso.string(from: $0) } ?? "nil"
        let sunsetIso = state.sunset.map { iso.string(from: $0) } ?? "nil"
        print("[HorizonSunData][App] coords lat=\(coords.latitude) lon=\(coords.longitude) tzId=\(tz.identifier) now=\(iso.string(from: now)) sunrise=\(sunriseIso) sunset=\(sunsetIso) sunriseText=\(state.sunriseText) sunsetText=\(state.sunsetText)")
        #endif

        return TodaySummary(
            phaseTitle: state.phase.title,
            sunrise: state.sunriseText,
            sunset: state.sunsetText,
            countdown: state.countdownText
        )
    }
}
