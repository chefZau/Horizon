//
//  SunDataService.swift
//  Shared sun/astronomy utilities for Horizon app + widget
//
//  Created by Codex on 2026-01-03.
//

import Foundation

struct Coordinates {
    let latitude: Double
    let longitude: Double
}

struct SunTimes {
    let sunrise: Date?
    let sunset: Date?
    let goldenHourStart: Date?
    let goldenHourEnd: Date?
    let blueHourStart: Date?
    let blueHourEnd: Date?
}

struct SunState {
    let phase: SunPhase
    let sunrise: Date?
    let sunset: Date?
    let sunriseText: String
    let sunsetText: String
    let countdownText: String
    let nextBoundary: Date?
}

enum SunPhase: CaseIterable {
    case preDawn
    case daytime
    case sunset
    case blueHourStart
    case blueHourRemaining
    case night

    var title: String {
        switch self {
        case .preDawn:
            return "Sunrise"
        case .daytime:
            return "Golden Hour"
        case .sunset:
            return "Sunset"
        case .blueHourStart:
            return "Blue Hour Start"
        case .blueHourRemaining:
            return "Blue Hour"
        case .night:
            return "Sunrise"
        }
    }

    var previewCountdown: String {
        switch self {
        case .preDawn:
            return "7h 34m"
        case .daytime:
            return "49m 30s"
        case .sunset:
            return "29m 38s"
        case .blueHourStart:
            return "5m 8s"
        case .blueHourRemaining:
            return "2m 4s"
        case .night:
            return "12h 32m"
        }
    }
}

enum SunDataService {
    static func computeSunState(
        now: Date,
        coords: Coordinates,
        tz: TimeZone,
        calendarIdentifier: Calendar.Identifier = .gregorian,
        timesToday: SunTimes? = nil,
        timesTomorrow: SunTimes? = nil,
        boundaries: [Date]? = nil
    ) -> SunState {
        var calendar = Calendar(identifier: calendarIdentifier)
        calendar.timeZone = tz

        let todayTimes = timesToday ?? calculateSunTimes(for: now, coords: coords, tz: tz, calendar: calendar)
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowTimes = timesTomorrow ?? calculateSunTimes(for: tomorrowDate, coords: coords, tz: tz, calendar: calendar)

        let phase = resolvePhase(now: now, times: todayTimes, nextDayTimes: tomorrowTimes)
        let points = boundaries ?? phaseBoundaries(timesToday: todayTimes, timesTomorrow: tomorrowTimes)
        let nextBoundary = points.first(where: { $0 > now }) ?? calendar.date(byAdding: .hour, value: 6, to: now)
        let countdown = nextBoundary.map { countdownText(from: now, to: $0) } ?? "0s"

        let formatter = timeFormatter(timeZone: tz)
        let sunriseText = formatter.string(from: todayTimes.sunrise ?? now)
        let sunsetText = formatter.string(from: todayTimes.sunset ?? now)

        #if DEBUG
        let iso = isoFormatter(timeZone: tz)
        let sunriseIso = todayTimes.sunrise.map { iso.string(from: $0) } ?? "nil"
        let sunsetIso = todayTimes.sunset.map { iso.string(from: $0) } ?? "nil"
        print("[HorizonSunData] coords lat=\(coords.latitude) lon=\(coords.longitude) tz=\(tz.identifier) now=\(iso.string(from: now)) sunrise=\(sunriseIso) sunset=\(sunsetIso) sunriseText=\(sunriseText) sunsetText=\(sunsetText)")
        #endif

        return SunState(
            phase: phase,
            sunrise: todayTimes.sunrise,
            sunset: todayTimes.sunset,
            sunriseText: sunriseText,
            sunsetText: sunsetText,
            countdownText: countdown,
            nextBoundary: nextBoundary
        )
    }

    static func calculateSunTimes(for date: Date, coords: Coordinates, tz: TimeZone, calendar: Calendar) -> SunTimes {
        let sunrise = solarEvent(for: date, coords: coords, altitude: -0.833, isSunrise: true, timeZone: tz, calendar: calendar)
        let sunset = solarEvent(for: date, coords: coords, altitude: -0.833, isSunrise: false, timeZone: tz, calendar: calendar)

        let goldenStart = solarEvent(for: date, coords: coords, altitude: 6.0, isSunrise: false, timeZone: tz, calendar: calendar)
        let goldenEnd = sunset

        let blueStart = solarEvent(for: date, coords: coords, altitude: -4.0, isSunrise: false, timeZone: tz, calendar: calendar)
        let blueEnd = solarEvent(for: date, coords: coords, altitude: -8.0, isSunrise: false, timeZone: tz, calendar: calendar)

        return SunTimes(
            sunrise: sunrise,
            sunset: sunset,
            goldenHourStart: goldenStart,
            goldenHourEnd: goldenEnd,
            blueHourStart: blueStart,
            blueHourEnd: blueEnd
        )
    }

    static func resolvePhase(now: Date, times: SunTimes, nextDayTimes: SunTimes?) -> SunPhase {
        let sunrise = times.sunrise
        let goldenStart = times.goldenHourStart ?? times.sunset
        let sunset = times.sunset
        let blueStart = times.blueHourStart
        let blueEnd = times.blueHourEnd

        if let sunrise, now < sunrise {
            return .preDawn
        }
        if let goldenStart, now < goldenStart {
            return .daytime
        }
        if let sunset, now < sunset {
            return .sunset
        }
        if let blueStart, let blueEnd, now >= blueStart, now < blueEnd {
            let midpoint = blueStart.addingTimeInterval(blueEnd.timeIntervalSince(blueStart) / 2)
            return now < midpoint ? .blueHourStart : .blueHourRemaining
        }
        if let blueEnd, now < blueEnd {
            return .blueHourRemaining
        }
        if let next = nextDayTimes?.sunrise, now < next {
            return .night
        }
        return .preDawn
    }

    static func phaseBoundaries(timesToday: SunTimes, timesTomorrow: SunTimes) -> [Date] {
        var points: [Date] = []
        if let sunrise = timesToday.sunrise { points.append(sunrise) }
        if let goldenStart = timesToday.goldenHourStart ?? timesToday.sunset { points.append(goldenStart) }
        if let sunset = timesToday.sunset { points.append(sunset) }
        if let blueStart = timesToday.blueHourStart { points.append(blueStart) }
        if let blueEnd = timesToday.blueHourEnd {
            if let blueStart = timesToday.blueHourStart {
                let mid = blueStart.addingTimeInterval(blueEnd.timeIntervalSince(blueStart) / 2)
                points.append(mid)
            }
            points.append(blueEnd)
        }
        if let nextSunrise = timesTomorrow.sunrise { points.append(nextSunrise) }
        return points.sorted()
    }

    static func countdownText(from start: Date, to end: Date) -> String {
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

    // MARK: - Internals

    private static func solarEvent(for date: Date, coords: Coordinates, altitude: Double, isSunrise: Bool, timeZone: TimeZone, calendar: Calendar) -> Date? {
        let zenith = 90.0 - altitude
        let degToRad = Double.pi / 180
        let radToDeg = 180 / Double.pi

        var calendar = calendar
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let baseDate = calendar.date(from: components) else { return nil }

        let N = Double(calendar.ordinality(of: .day, in: .year, for: baseDate) ?? 1)
        let lngHour = coords.longitude / 15.0

        let tBase = isSunrise ? 6.0 : 18.0
        let t = N + ((tBase - lngHour) / 24.0)

        let M = (0.9856 * t) - 3.289

        var L = M + (1.916 * sin(M * degToRad)) + (0.020 * sin(2 * M * degToRad)) + 282.634
        L = normalizeDegrees(L)

        var RA = radToDeg * atan(0.91764 * tan(L * degToRad))
        RA = normalizeDegrees(RA)

        let Lquadrant = floor(L / 90.0) * 90.0
        let RAquadrant = floor(RA / 90.0) * 90.0
        RA = RA + (Lquadrant - RAquadrant)
        RA /= 15.0

        let sinDec = 0.39782 * sin(L * degToRad)
        let cosDec = cos(asin(sinDec))

        let cosH = (cos(zenith * degToRad) - (sinDec * sin(coords.latitude * degToRad))) / (cosDec * cos(coords.latitude * degToRad))
        if cosH > 1 || cosH < -1 {
            return nil
        }

        var H = isSunrise ? (360.0 - radToDeg * acos(cosH)) : (radToDeg * acos(cosH))
        H /= 15.0

        let T = H + RA - (0.06571 * t) - 6.622
        var UT = T - lngHour
        UT = normalizeHours(UT)

        let hours = Int(UT)
        let minutes = Int((UT - Double(hours)) * 60)
        let seconds = Int((((UT - Double(hours)) * 60) - Double(minutes)) * 60)

        var resultComponents = components
        resultComponents.hour = hours
        resultComponents.minute = minutes
        resultComponents.second = seconds
        resultComponents.nanosecond = 0
        guard let utcTZ = TimeZone(secondsFromGMT: 0) else { return nil }
        resultComponents.timeZone = utcTZ

        var utcCalendar = Calendar(identifier: calendar.identifier)
        utcCalendar.timeZone = utcTZ
        guard let utcDate = utcCalendar.date(from: resultComponents) else { return nil }

        // `utcDate` already represents the absolute instant of the event. Formatting with the
        // desired time zone will present it correctly, so we return the UTC-based Date here.
        return utcDate
    }

    private static func normalizeDegrees(_ value: Double) -> Double {
        var v = value
        while v < 0 { v += 360 }
        while v >= 360 { v -= 360 }
        return v
    }

    private static func normalizeHours(_ value: Double) -> Double {
        var v = value
        while v < 0 { v += 24 }
        while v >= 24 { v -= 24 }
        return v
    }

    private static func timeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        return formatter
    }

    private static func isoFormatter(timeZone: TimeZone) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timeZone
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}
