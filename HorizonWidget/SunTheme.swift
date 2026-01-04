//
//  SunTheme.swift
//  HorizonWidget
//
//  Created by Codex on 2026-01-03.
//

import SwiftUI

struct SunTheme {
    let background: LinearGradient
    let horizonColor: Color
    let isLightBackground: Bool
    let sunriseTimeColor: Color
    let sunsetTimeColor: Color
    let groundTopColor: Color
    let groundBottomColor: Color
    let horizonHighlightColor: Color

    var topTextColor: Color {
        isLightBackground ? Color.black.opacity(0.75) : Color.white.opacity(0.85)
    }
}

extension SunTheme {
    static func theme(for phase: SunPhase) -> SunTheme {
        switch phase {
        case .preDawn:
            return SunTheme(
                background: LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.98, blue: 0.96),
                        Color(red: 0.94, green: 0.93, blue: 0.90)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                horizonColor: Color(red: 1.00, green: 0.80, blue: 0.52).opacity(0.8),
                isLightBackground: true,
                sunriseTimeColor: Color(red: 1.0, green: 0.55, blue: 0.15),
                sunsetTimeColor: Color(red: 0.20, green: 0.55, blue: 1.0),
                groundTopColor: Color(red: 0.94, green: 0.92, blue: 0.88),
                groundBottomColor: Color(red: 0.86, green: 0.83, blue: 0.80),
                horizonHighlightColor: Color.white.opacity(0.55)
            )
        case .daytime:
            return SunTheme(
                background: LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.68, blue: 0.97),
                        Color(red: 1.00, green: 0.63, blue: 0.27)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                horizonColor: Color(red: 1.00, green: 0.82, blue: 0.55).opacity(0.9),
                isLightBackground: false,
                sunriseTimeColor: Color.white.opacity(0.92),
                sunsetTimeColor: Color.white.opacity(0.92),
                groundTopColor: Color(red: 1.00, green: 0.72, blue: 0.32),
                groundBottomColor: Color(red: 0.92, green: 0.48, blue: 0.12),
                horizonHighlightColor: Color(red: 1.0, green: 0.95, blue: 0.78).opacity(0.9)
            )
        case .sunset:
            return SunTheme(
                background: LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.76, blue: 0.24),
                        Color(red: 0.93, green: 0.38, blue: 0.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                horizonColor: Color(red: 1.00, green: 0.85, blue: 0.60).opacity(0.9),
                isLightBackground: false,
                sunriseTimeColor: Color.white.opacity(0.92),
                sunsetTimeColor: Color.white.opacity(0.92),
                groundTopColor: Color(red: 0.95, green: 0.46, blue: 0.12),
                groundBottomColor: Color(red: 0.65, green: 0.22, blue: 0.02),
                horizonHighlightColor: Color(red: 1.0, green: 0.88, blue: 0.6).opacity(0.85)
            )
        case .blueHourStart:
            return SunTheme(
                background: LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.34, blue: 0.14),
                        Color(red: 0.42, green: 0.11, blue: 0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                horizonColor: Color(red: 1.00, green: 0.84, blue: 0.76).opacity(0.9),
                isLightBackground: false,
                sunriseTimeColor: Color(red: 1.0, green: 0.92, blue: 0.86),
                sunsetTimeColor: Color(red: 1.0, green: 0.92, blue: 0.86),
                groundTopColor: Color(red: 0.32, green: 0.10, blue: 0.05),
                groundBottomColor: Color(red: 0.14, green: 0.05, blue: 0.03),
                horizonHighlightColor: Color(red: 1.0, green: 0.74, blue: 0.60).opacity(0.85)
            )
        case .blueHourRemaining:
            return SunTheme(
                background: LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.63, blue: 0.88),
                        Color(red: 0.18, green: 0.07, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                horizonColor: Color(red: 0.80, green: 0.74, blue: 1.00).opacity(0.8),
                isLightBackground: false,
                sunriseTimeColor: Color(red: 0.94, green: 0.90, blue: 0.98),
                sunsetTimeColor: Color(red: 0.94, green: 0.90, blue: 0.98),
                groundTopColor: Color(red: 0.16, green: 0.08, blue: 0.16),
                groundBottomColor: Color(red: 0.08, green: 0.05, blue: 0.12),
                horizonHighlightColor: Color(red: 0.95, green: 0.88, blue: 1.0).opacity(0.7)
            )
        case .night:
            return SunTheme(
                background: LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.10, blue: 0.18),
                        Color(red: 0.01, green: 0.02, blue: 0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                horizonColor: Color(red: 0.70, green: 0.76, blue: 0.94).opacity(0.7),
                isLightBackground: false,
                sunriseTimeColor: Color.white.opacity(0.92),
                sunsetTimeColor: Color.white.opacity(0.92),
                groundTopColor: Color(red: 0.20, green: 0.22, blue: 0.35),
                groundBottomColor: Color(red: 0.06, green: 0.07, blue: 0.12),
                horizonHighlightColor: Color(red: 0.8, green: 0.85, blue: 1.0).opacity(0.5)
            )
        }
    }
}
