//
//  HorizonWidget.swift
//  HorizonWidget
//
//  Created by Luca Zhou on 2026-01-03.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    private let fallbackLatitude: Double = 43.6532
    private let fallbackLongitude: Double = -79.3832
    private let maxCoordinateAge: TimeInterval = 12 * 3600
    private let fallbackTimeZone: TimeZone = TimeZone(identifier: "America/Toronto") ?? Calendar.current.timeZone

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), model: .init(phase: .daytime, sunrise: "06:05", sunset: "18:13", countdownText: "49m 30s"))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let now = Date()
        let coordinates = loadCoordinates()
        var cal = Calendar.current
        cal.timeZone = coordinates.tz
        let timesToday = SunAstronomy.calculateSunTimes(for: now, latitude: coordinates.lat, longitude: coordinates.lon, timeZone: coordinates.tz, calendar: cal)
        let timesTomorrow = SunAstronomy.calculateSunTimes(for: cal.date(byAdding: .day, value: 1, to: now) ?? now, latitude: coordinates.lat, longitude: coordinates.lon, timeZone: coordinates.tz, calendar: cal)
        return makeEntry(for: now, timesToday: timesToday, timesTomorrow: timesTomorrow, calendar: cal, timeZone: coordinates.tz)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        let coordinates = loadCoordinates()
        var cal = Calendar.current
        cal.timeZone = coordinates.tz
        let timesToday = SunAstronomy.calculateSunTimes(for: currentDate, latitude: coordinates.lat, longitude: coordinates.lon, timeZone: coordinates.tz, calendar: cal)
        let timesTomorrow = SunAstronomy.calculateSunTimes(for: cal.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate, latitude: coordinates.lat, longitude: coordinates.lon, timeZone: coordinates.tz, calendar: cal)

        let boundaries = phaseBoundaries(timesToday: timesToday, timesTomorrow: timesTomorrow)

        var entryDates: [Date] = [currentDate]
        entryDates.append(contentsOf: boundaries.filter { $0 > currentDate })

        for date in entryDates {
            let entry = makeEntry(for: date, timesToday: timesToday, timesTomorrow: timesTomorrow, nextBoundaries: boundaries, calendar: cal, timeZone: coordinates.tz)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    // MARK: - Helpers

    func makeEntry(for date: Date, timesToday: SunTimes, timesTomorrow: SunTimes, nextBoundaries: [Date]? = nil, calendar: Calendar? = nil, timeZone: TimeZone? = nil) -> SimpleEntry {
        let tz = timeZone ?? fallbackTimeZone
        var cal = calendar ?? Calendar.current
        cal.timeZone = tz
        let formatter = timeFormatter(timeZone: tz)
        let sunriseText = formatter.string(from: timesToday.sunrise ?? date)
        let sunsetText = formatter.string(from: timesToday.sunset ?? date)

        let phase = SunAstronomy.resolvePhase(now: date, times: timesToday, nextDayTimes: timesTomorrow)
        let boundaries = nextBoundaries ?? phaseBoundaries(timesToday: timesToday, timesTomorrow: timesTomorrow)
        let nextBoundary = boundaries.first(where: { $0 > date }) ?? cal.date(byAdding: .hour, value: 6, to: date)!
        let countdown = countdownText(from: date, to: nextBoundary)

        let model = SunWidgetModel(phase: phase, sunrise: sunriseText, sunset: sunsetText, countdownText: countdown)
        return SimpleEntry(date: date, model: model)
    }

    private func phaseBoundaries(timesToday: SunTimes, timesTomorrow: SunTimes) -> [Date] {
        var points: [Date] = []
        if let sunrise = timesToday.sunrise { points.append(sunrise) }
        if let goldenStart = timesToday.goldenHourStart ?? timesToday.sunset { points.append(goldenStart) }
        if let sunset = timesToday.sunset { points.append(sunset) }
        if let blueStart = timesToday.blueHourStart { points.append(blueStart) }
        if let blueEnd = timesToday.blueHourEnd {
            // Insert a midpoint to switch from start to remaining.
            if let blueStart = timesToday.blueHourStart {
                let mid = blueStart.addingTimeInterval(blueEnd.timeIntervalSince(blueStart) / 2)
                points.append(mid)
            }
            points.append(blueEnd)
        }
        if let nextSunrise = timesTomorrow.sunrise { points.append(nextSunrise) }
        return points.sorted()
    }

    private func timeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        return formatter
    }

    private func countdownText(from start: Date, to end: Date) -> String {
        let interval = Int(end.timeIntervalSince(start).rounded())
        if interval <= 0 { return "0s" }

        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    private func loadCoordinates() -> (lat: Double, lon: Double, tz: TimeZone, ts: Double) {
        guard let defaults = UserDefaults(suiteName: AppGroup.id) else {
            print("[HorizonWidgetRead] fallback: app group unavailable, using lat=\(fallbackLatitude) lon=\(fallbackLongitude)")
            return (fallbackLatitude, fallbackLongitude, fallbackTimeZone, 0)
        }

        let timestamp = defaults.double(forKey: "timestamp")
        let age = Date().timeIntervalSince1970 - timestamp
        guard let lat = defaults.object(forKey: "latitude") as? Double,
              let lon = defaults.object(forKey: "longitude") as? Double,
              timestamp > 0 else {
            print("[HorizonWidgetRead] fallback: missing stored location, using lat=\(fallbackLatitude) lon=\(fallbackLongitude)")
            return (fallbackLatitude, fallbackLongitude, fallbackTimeZone, 0)
        }

        let tzId = defaults.string(forKey: "timeZoneId")
        let tz = TimeZone(identifier: tzId ?? "") ?? fallbackTimeZone

        if age > maxCoordinateAge {
            print("[HorizonWidgetRead] fallback: stored location stale age=\(age)s ts=\(timestamp), using lat=\(fallbackLatitude) lon=\(fallbackLongitude) tz=\(tz.identifier)")
            return (fallbackLatitude, fallbackLongitude, fallbackTimeZone, timestamp)
        }

        print("[HorizonWidgetRead] using stored coords lat=\(lat) lon=\(lon) ts=\(timestamp) age=\(age)s tzId=\(tz.identifier)")
        return (lat, lon, tz, timestamp)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let model: SunWidgetModel
}

struct HorizonWidgetEntryView : View {
    var entry: Provider.Entry

    private var theme: SunTheme {
        SunTheme.theme(for: entry.model.phase)
    }

    var body: some View {
        SunWidgetView(model: entry.model)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                theme.background
            }
    }
}

struct HorizonWidget: Widget {
    let kind: String = "HorizonWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            HorizonWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .supportedFamilies([.systemMedium])
    }
}

// Preview samples covering all phases.
private let previewEntries: [SimpleEntry] = {
    let now = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.timeZone = Calendar.current.timeZone

    let cal = Calendar.current
    let todayTimes = SunAstronomy.calculateSunTimes(for: now, latitude: 43.6532, longitude: -79.3832, timeZone: Calendar.current.timeZone, calendar: cal)
    let sunriseText = formatter.string(from: todayTimes.sunrise ?? now)
    let sunsetText = formatter.string(from: todayTimes.sunset ?? now)

    return [
        SimpleEntry(date: now.addingTimeInterval(0 * 60), model: SunWidgetModel(phase: .preDawn, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.preDawn.countdownText)),
        SimpleEntry(date: now.addingTimeInterval(1 * 60), model: SunWidgetModel(phase: .daytime, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.daytime.countdownText)),
        SimpleEntry(date: now.addingTimeInterval(2 * 60), model: SunWidgetModel(phase: .sunset, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.sunset.countdownText)),
        SimpleEntry(date: now.addingTimeInterval(3 * 60), model: SunWidgetModel(phase: .blueHourStart, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.blueHourStart.countdownText)),
        SimpleEntry(date: now.addingTimeInterval(4 * 60), model: SunWidgetModel(phase: .blueHourRemaining, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.blueHourRemaining.countdownText)),
        SimpleEntry(date: now.addingTimeInterval(5 * 60), model: SunWidgetModel(phase: .night, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.night.countdownText))
    ]
}()

#Preview(as: .systemMedium) {
    HorizonWidget()
} timeline: {
    previewEntries[0]
    previewEntries[1]
    previewEntries[2]
    previewEntries[3]
    previewEntries[4]
    previewEntries[5]
}
