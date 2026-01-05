//
//  AboutView.swift
//  Horizon
//
//  Created by Codex on 2026-01-03.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Horizon is a photography-friendly widget that shows sunrise, sunset, golden hour, and blue hour timings with a simple horizon visualization.")
                .font(.body)
            Text("Inspired by Apple Weather’s elegant gradients and focused on keeping the best light front and center.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("License: MIT")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
