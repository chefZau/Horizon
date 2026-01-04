//
//  HorizonFillShape.swift
//  HorizonWidget
//
//  Created by Codex on 2026-01-03.
//

import SwiftUI

/// A filled horizon band: a soft arc that fills the lower portion of the widget.
struct HorizonFillShape: Shape {
    func path(in rect: CGRect) -> Path {
        let baseline = rect.height * 0.68
        let controlY = rect.height * 0.30

        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: baseline))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: baseline),
            control: CGPoint(x: rect.midX, y: controlY)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}
