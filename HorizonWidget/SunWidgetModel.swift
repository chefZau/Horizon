//
//  SunWidgetModel.swift
//  HorizonWidget
//
//  Created by Codex on 2026-01-03.
//

import Foundation

struct SunWidgetModel {
    let phase: SunPhase
    let sunrise: String
    let sunset: String
    let countdownText: String

    init(phase: SunPhase, sunrise: String = "06:05", sunset: String = "18:13", countdownText: String = "") {
        self.phase = phase
        self.sunrise = sunrise
        self.sunset = sunset
        self.countdownText = countdownText
    }

    var phaseTitle: String { phase.title }
}
