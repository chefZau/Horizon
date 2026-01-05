//
//  AppGroupStore.swift
//  Horizon
//
//  Created by Codex on 2026-01-03.
//

import Foundation

struct StoredLocationData {
    let latitude: Double
    let longitude: Double
    let timestamp: TimeInterval
    let timeZone: TimeZone
    let city: String?
    let isAutomatic: Bool
}

enum AppGroupStore {
    private static let fallbackLatitude: Double = 43.6532
    private static let fallbackLongitude: Double = -79.3832
    private static let fallbackTimeZone: TimeZone = TimeZone(identifier: "America/Toronto") ?? .current
    private static let maxCoordinateAge: TimeInterval = 12 * 3600

    static func loadLocation() -> StoredLocationData {
        guard let defaults = UserDefaults(suiteName: AppGroup.id) else {
            return fallback()
        }

        let ts = defaults.double(forKey: "timestamp")
        let age = Date().timeIntervalSince1970 - ts
        guard let lat = defaults.object(forKey: "latitude") as? Double,
              let lon = defaults.object(forKey: "longitude") as? Double,
              ts > 0 else {
            return fallback()
        }

        let tzId = defaults.string(forKey: "timeZoneId")
        let tz = TimeZone(identifier: tzId ?? "") ?? fallbackTimeZone
        let city = defaults.string(forKey: "cityName")
        let isAuto = defaults.object(forKey: "isAutomaticLocation") as? Bool ?? true

        if age > maxCoordinateAge {
            return fallback()
        }

        return StoredLocationData(
            latitude: lat,
            longitude: lon,
            timestamp: ts,
            timeZone: tz,
            city: city,
            isAutomatic: isAuto
        )
    }

    private static func fallback() -> StoredLocationData {
        StoredLocationData(
            latitude: fallbackLatitude,
            longitude: fallbackLongitude,
            timestamp: 0,
            timeZone: fallbackTimeZone,
            city: "Toronto",
            isAutomatic: true
        )
    }
}
