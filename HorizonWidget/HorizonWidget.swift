//
//  HorizonWidget.swift
//  HorizonWidget
//
//  Created by Luca Zhou on 2026-01-03.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    private let fallbackCoordinates = Coordinates(latitude: 43.6532, longitude: -79.3832)
    private let maxCoordinateAge: TimeInterval = 12 * 3600
    private let fallbackTimeZone: TimeZone = TimeZone(identifier: "America/Toronto") ?? Calendar.current.timeZone

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), model: .init(phase: .daytime, sunrise: "06:05", sunset: "18:13", countdownText: "49m 30s"))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let now = Date()
        let location = loadCoordinates()
        let calendar = makeCalendar(tz: location.tz)
        let timesToday = SunDataService.calculateSunTimes(for: now, coords: location.coords, tz: location.tz, calendar: calendar)
        let timesTomorrow = SunDataService.calculateSunTimes(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now, coords: location.coords, tz: location.tz, calendar: calendar)
        return makeEntry(for: now, timesToday: timesToday, timesTomorrow: timesTomorrow, calendar: calendar, timeZone: location.tz, coords: location.coords)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        let location = loadCoordinates()
        let cal = makeCalendar(tz: location.tz)
        let timesToday = SunDataService.calculateSunTimes(for: currentDate, coords: location.coords, tz: location.tz, calendar: cal)
        let timesTomorrow = SunDataService.calculateSunTimes(for: cal.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate, coords: location.coords, tz: location.tz, calendar: cal)

        let boundaries = SunDataService.phaseBoundaries(timesToday: timesToday, timesTomorrow: timesTomorrow)

        var entryDates: [Date] = [currentDate]
        entryDates.append(contentsOf: boundaries.filter { $0 > currentDate })

        for date in entryDates {
            let entry = makeEntry(for: date, timesToday: timesToday, timesTomorrow: timesTomorrow, nextBoundaries: boundaries, calendar: cal, timeZone: location.tz, coords: location.coords)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    // MARK: - Helpers

    func makeEntry(for date: Date, timesToday: SunTimes, timesTomorrow: SunTimes, nextBoundaries: [Date]? = nil, calendar: Calendar? = nil, timeZone: TimeZone? = nil, coords: Coordinates? = nil) -> SimpleEntry {
        let tz = timeZone ?? fallbackTimeZone
        var cal = calendar ?? makeCalendar(tz: tz)
        cal.timeZone = tz
        let boundaries = nextBoundaries ?? SunDataService.phaseBoundaries(timesToday: timesToday, timesTomorrow: timesTomorrow)

        let state = SunDataService.computeSunState(
            now: date,
            coords: coords ?? fallbackCoordinates,
            tz: tz,
            calendarIdentifier: cal.identifier,
            timesToday: timesToday,
            timesTomorrow: timesTomorrow,
            boundaries: boundaries
        )

        let model = SunWidgetModel(phase: state.phase, sunrise: state.sunriseText, sunset: state.sunsetText, countdownText: state.countdownText)
        return SimpleEntry(date: date, model: model)
    }

    private func makeCalendar(tz: TimeZone) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal
    }

    private func loadCoordinates() -> (coords: Coordinates, tz: TimeZone, ts: Double) {
        guard let defaults = UserDefaults(suiteName: AppGroup.id) else {
            print("[HorizonWidgetRead] fallback: app group unavailable, using lat=\(fallbackCoordinates.latitude) lon=\(fallbackCoordinates.longitude)")
            return (fallbackCoordinates, fallbackTimeZone, 0)
        }

        let timestamp = defaults.double(forKey: "timestamp")
        let age = Date().timeIntervalSince1970 - timestamp
        guard let lat = defaults.object(forKey: "latitude") as? Double,
              let lon = defaults.object(forKey: "longitude") as? Double,
              timestamp > 0 else {
            print("[HorizonWidgetRead] fallback: missing stored location, using lat=\(fallbackCoordinates.latitude) lon=\(fallbackCoordinates.longitude)")
            return (fallbackCoordinates, fallbackTimeZone, 0)
        }

        let tzId = defaults.string(forKey: "timeZoneId")
        let tz = TimeZone(identifier: tzId ?? "") ?? fallbackTimeZone

        if age > maxCoordinateAge {
            print("[HorizonWidgetRead] fallback: stored location stale age=\(age)s ts=\(timestamp), using lat=\(fallbackCoordinates.latitude) lon=\(fallbackCoordinates.longitude) tz=\(tz.identifier)")
            return (fallbackCoordinates, fallbackTimeZone, timestamp)
        }

        let coords = Coordinates(latitude: lat, longitude: lon)
        #if DEBUG
        let iso = ISO8601DateFormatter()
        iso.timeZone = tz
        print("[HorizonWidgetRead] using stored coords lat=\(lat) lon=\(lon) ts=\(timestamp) age=\(age)s tzId=\(tz.identifier)")
        #endif
        return (coords, tz, timestamp)
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

    let coords = Coordinates(latitude: 43.6532, longitude: -79.3832)
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = Calendar.current.timeZone
    let todayTimes = SunDataService.calculateSunTimes(for: now, coords: coords, tz: Calendar.current.timeZone, calendar: cal)
    let sunriseText = formatter.string(from: todayTimes.sunrise ?? now)
    let sunsetText = formatter.string(from: todayTimes.sunset ?? now)

    return [
        SimpleEntry(date: now.addingTimeInterval(0 * 60), model: SunWidgetModel(phase: .preDawn, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.preDawn.previewCountdown)),
        SimpleEntry(date: now.addingTimeInterval(1 * 60), model: SunWidgetModel(phase: .daytime, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.daytime.previewCountdown)),
        SimpleEntry(date: now.addingTimeInterval(2 * 60), model: SunWidgetModel(phase: .sunset, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.sunset.previewCountdown)),
        SimpleEntry(date: now.addingTimeInterval(3 * 60), model: SunWidgetModel(phase: .blueHourStart, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.blueHourStart.previewCountdown)),
        SimpleEntry(date: now.addingTimeInterval(4 * 60), model: SunWidgetModel(phase: .blueHourRemaining, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.blueHourRemaining.previewCountdown)),
        SimpleEntry(date: now.addingTimeInterval(5 * 60), model: SunWidgetModel(phase: .night, sunrise: sunriseText, sunset: sunsetText, countdownText: SunPhase.night.previewCountdown))
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
