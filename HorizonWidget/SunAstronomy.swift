//
//  SunAstronomy.swift
//  HorizonWidget
//
//  Created by Codex on 2026-01-03.
//

import Foundation

struct SunTimes {
    let sunrise: Date?
    let sunset: Date?
    let goldenHourStart: Date?
    let goldenHourEnd: Date?
    let blueHourStart: Date?
    let blueHourEnd: Date?
}

enum SunAstronomy {
    /// Compute key solar times for a given date and location using a NOAA-style algorithm.
    static func calculateSunTimes(for date: Date, latitude: Double, longitude: Double, timeZone: TimeZone, calendar: Calendar) -> SunTimes {
        let sunrise = solarEvent(for: date, latitude: latitude, longitude: longitude, altitude: -0.833, isSunrise: true, timeZone: timeZone, calendar: calendar)
        let sunset = solarEvent(for: date, latitude: latitude, longitude: longitude, altitude: -0.833, isSunrise: false, timeZone: timeZone, calendar: calendar)

        // Evening golden hour: when the sun is ~6° above horizon before sunset.
        let goldenStart = solarEvent(for: date, latitude: latitude, longitude: longitude, altitude: 6.0, isSunrise: false, timeZone: timeZone, calendar: calendar)
        let goldenEnd = sunset

        // Blue hour: between ~-4° and -8° after sunset.
        let blueStart = solarEvent(for: date, latitude: latitude, longitude: longitude, altitude: -4.0, isSunrise: false, timeZone: timeZone, calendar: calendar)
        let blueEnd = solarEvent(for: date, latitude: latitude, longitude: longitude, altitude: -8.0, isSunrise: false, timeZone: timeZone, calendar: calendar)

        return SunTimes(
            sunrise: sunrise,
            sunset: sunset,
            goldenHourStart: goldenStart,
            goldenHourEnd: goldenEnd,
            blueHourStart: blueStart,
            blueHourEnd: blueEnd
        )
    }

    /// Determine phase from current time and computed times (optionally using next day's sunrise for night).
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
        return .night
    }

    // MARK: - Private helpers

    /// Solar event time at a given altitude (degrees above horizon; negative means below), using simplified NOAA algorithm.
    private static func solarEvent(for date: Date, latitude: Double, longitude: Double, altitude: Double, isSunrise: Bool, timeZone: TimeZone, calendar: Calendar) -> Date? {
        // Convert altitude to solar zenith angle.
        let zenith = 90.0 - altitude
        let degToRad = Double.pi / 180
        let radToDeg = 180 / Double.pi

        var calendar = calendar
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let baseDate = calendar.date(from: components) else { return nil }

        let N = Double(calendar.ordinality(of: .day, in: .year, for: baseDate) ?? 1)
        let lngHour = longitude / 15.0

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

        let cosH = (cos(zenith * degToRad) - (sinDec * sin(latitude * degToRad))) / (cosDec * cos(latitude * degToRad))
        if cosH > 1 || cosH < -1 {
            return nil // Sun never rises/sets at this location/date for given altitude.
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

        // utcDate represents the absolute UTC moment of the solar event.
        // Do not add the local offset here; downstream formatters handle local time.
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
}
