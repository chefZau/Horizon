//
//  SunPhase.swift
//  HorizonWidget
//
//  Created by Codex on 2026-01-03.
//

import SwiftUI

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

    var countdownText: String {
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
