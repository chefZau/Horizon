//
//  LocationManager.swift
//  Horizon
//
//  Created by Codex on 2026-01-03.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation
import WidgetKit

@MainActor
final class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    private func persistLocation(_ coordinate: CLLocationCoordinate2D, tzId: String?, city: String?, timestamp: TimeInterval) {
        guard let defaults = UserDefaults(suiteName: AppGroup.id) else { return }
        defaults.set(coordinate.latitude, forKey: "latitude")
        defaults.set(coordinate.longitude, forKey: "longitude")
        defaults.set(timestamp, forKey: "timestamp")
        if let tzId {
            defaults.set(tzId, forKey: "timeZoneId")
        } else {
            defaults.removeObject(forKey: "timeZoneId")
        }
        if let city {
            defaults.set(city, forKey: "cityName")
        }
        defaults.set(true, forKey: "isAutomaticLocation")
        defaults.synchronize()

        let lat = defaults.double(forKey: "latitude")
        let lon = defaults.double(forKey: "longitude")
        let savedTs = defaults.double(forKey: "timestamp")
        let savedTz = defaults.string(forKey: "timeZoneId") ?? "nil"
        let savedCity = defaults.string(forKey: "cityName") ?? "nil"
        print("[HorizonAppGroupWrite] stored lat=\(lat) lon=\(lon) ts=\(savedTs) tzId=\(savedTz) city=\(savedCity)")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        Task { @MainActor in
            let ts = Date().timeIntervalSince1970
            let defaultsAvailable = UserDefaults(suiteName: AppGroup.id) != nil
            print("[HorizonAppGroupWrite] received location lat=\(coord.latitude) lon=\(coord.longitude) ts=\(ts) defaultsAvailable=\(defaultsAvailable)")
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { placemarks, error in
                if let error {
                    print("[HorizonAppGroupWrite] reverse geocode failed: \(error.localizedDescription)")
                    self.persistLocation(coord, tzId: nil, city: nil, timestamp: ts)
                    return
                }
                let placemark = placemarks?.first
                let tzId = placemark?.timeZone?.identifier
                let city = [placemark?.locality, placemark?.administrativeArea, placemark?.country]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                print("[HorizonAppGroupWrite] reverse geocode tzId=\(tzId ?? "nil") city=\(city ?? "nil")")
                self.persistLocation(coord, tzId: tzId, city: city, timestamp: ts)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }
}
