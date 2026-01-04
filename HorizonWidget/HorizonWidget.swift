//
//  HorizonWidget.swift
//  HorizonWidget
//
//  Created by Luca Zhou on 2026-01-03.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    private let latitude: Double = 43.6532
    private let longitude: Double = -79.3832
    private let timeZone: TimeZone = Calendar.current.timeZone
    var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), model: .init(phase: .daytime, sunrise: "06:05", sunset: "18:13", countdownText: "49分钟30秒"))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let now = Date()
        let timesToday = SunAstronomy.calculateSunTimes(for: now, latitude: latitude, longitude: longitude, timeZone: timeZone, calendar: calendar)
        let timesTomorrow = SunAstronomy.calculateSunTimes(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now, latitude: latitude, longitude: longitude, timeZone: timeZone, calendar: calendar)
        return makeEntry(for: now, timesToday: timesToday, timesTomorrow: timesTomorrow)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        let timesToday = SunAstronomy.calculateSunTimes(for: currentDate, latitude: latitude, longitude: longitude, timeZone: timeZone, calendar: calendar)
        let timesTomorrow = SunAstronomy.calculateSunTimes(for: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate, latitude: latitude, longitude: longitude, timeZone: timeZone, calendar: calendar)

        let boundaries = phaseBoundaries(timesToday: timesToday, timesTomorrow: timesTomorrow)

        var entryDates: [Date] = [currentDate]
        entryDates.append(contentsOf: boundaries.filter { $0 > currentDate })

        for date in entryDates {
            let entry = makeEntry(for: date, timesToday: timesToday, timesTomorrow: timesTomorrow, nextBoundaries: boundaries)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    // MARK: - Helpers

    func makeEntry(for date: Date, timesToday: SunTimes, timesTomorrow: SunTimes, nextBoundaries: [Date]? = nil) -> SimpleEntry {
        let formatter = timeFormatter()
        let sunriseText = formatter.string(from: timesToday.sunrise ?? date)
        let sunsetText = formatter.string(from: timesToday.sunset ?? date)

        let phase = SunAstronomy.resolvePhase(now: date, times: timesToday, nextDayTimes: timesTomorrow)
        let boundaries = nextBoundaries ?? phaseBoundaries(timesToday: timesToday, timesTomorrow: timesTomorrow)
        let nextBoundary = boundaries.first(where: { $0 > date }) ?? calendar.date(byAdding: .hour, value: 6, to: date)!
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

    private func timeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        return formatter
    }

    private func countdownText(from start: Date, to end: Date) -> String {
        let interval = Int(end.timeIntervalSince(start).rounded())
        if interval <= 0 { return "0秒" }

        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60

        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
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
