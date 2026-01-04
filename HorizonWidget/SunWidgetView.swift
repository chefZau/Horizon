//
//  SunWidgetView.swift
//  HorizonWidget
//
//  Created by Codex on 2026-01-03.
//

import SwiftUI
import WidgetKit

struct SunWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let model: SunWidgetModel

    var body: some View {
        let theme = SunTheme.theme(for: model.phase)

        GeometryReader { geo in
            ZStack {
                // White/bright seam above the ground.
                HorizonArcShape()
                    .stroke(theme.horizonHighlightColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .blur(radius: 8)

                // Ground fill below the seam.
                HorizonFillShape()
                    .fill(
                        LinearGradient(
                            colors: [theme.groundTopColor, theme.groundBottomColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(
                        HorizonFillShape()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.9),
                                        Color.black.opacity(0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blur(radius: 6)
                    )

                content(for: theme)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(ContainerRelativeShape())
        }
    }

    @ViewBuilder
    private func content(for theme: SunTheme) -> some View {
        let textFont: Font = .callout
        switch family {
        case .systemMedium:
            VStack {
                HStack(alignment: .firstTextBaseline) {
                    phaseBadge(title: model.phaseTitle, color: theme.sunriseTimeColor, textColor: theme.topTextColor)
                    Spacer()
                    Text(model.countdownText)
                        .font(textFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.topTextColor)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline) {
                    timeValue(model.sunrise, alignment: .leading, valueColor: theme.sunriseTimeColor, font: textFont)
                    Spacer()
                    timeValue(model.sunset, alignment: .trailing, valueColor: theme.sunsetTimeColor, font: textFont)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        default:
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    phaseBadge(title: model.phaseTitle, color: theme.sunriseTimeColor, textColor: theme.topTextColor)
                    Spacer(minLength: 8)
                    Text(model.countdownText)
                        .font(textFont)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.topTextColor)
                }

                Spacer(minLength: 6)

                HStack {
                    timeValue(model.sunrise, alignment: .leading, valueColor: theme.sunriseTimeColor, font: textFont)
                    Spacer()
                    timeValue(model.sunset, alignment: .trailing, valueColor: theme.sunsetTimeColor, font: textFont)
                }
            }
            .padding(14)
        }
    }

    @ViewBuilder
    private func timeValue(_ value: String, alignment: HorizontalAlignment, valueColor: Color, font: Font) -> some View {
        Text(value)
            .font(font)
            .monospacedDigit()
            .fontWeight(.semibold)
            .foregroundStyle(valueColor)
    }

    @ViewBuilder
    private func phaseBadge(title: String, color: Color, textColor: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(textColor)
        }
    }
}

#Preview("SunWidgetView - All Phases") {
    Group {
        ForEach(Array(SunPhase.allCases.enumerated()), id: \.offset) { _, phase in
            SunWidgetView(model: .init(phase: phase))
                .frame(width: 170, height: 170)
        }
    }
}
