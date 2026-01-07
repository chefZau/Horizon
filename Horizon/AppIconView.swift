//
//  AppIconView.swift
//  Horizon
//
//  Created by Codex on 2026-01-04.
//

import SwiftUI
import UIKit

private struct AppIconOption: Identifiable, Hashable {
    let id: String
    let title: String
    let iconName: String?
    let gradient: [Color]
}

struct AppIconView: View {
    @State private var currentIcon: String? = UIApplication.shared.alternateIconName
    @State private var message: String?

    private let options: [AppIconOption] = [
        .init(id: "default", title: "System Default", iconName: nil, gradient: [.blue, .orange]),
        .init(id: "sunrise", title: "Sunrise", iconName: "Sunrise", gradient: [Color(red: 1.0, green: 0.82, blue: 0.63), Color(red: 1.0, green: 0.94, blue: 0.86)]),
        .init(id: "daytime", title: "Daytime", iconName: "Daytime", gradient: [Color(red: 0.08, green: 0.74, blue: 0.96), Color(red: 1.0, green: 0.78, blue: 0.47)]),
        .init(id: "golden", title: "Golden Hour", iconName: "Golden", gradient: [Color(red: 1.0, green: 0.72, blue: 0.26), Color(red: 1.0, green: 0.55, blue: 0.1)]),
        .init(id: "sunset", title: "Sunset", iconName: "Sunset", gradient: [Color(red: 1.0, green: 0.56, blue: 0.24), Color(red: 0.75, green: 0.28, blue: 0.05)]),
        .init(id: "bluehour", title: "Blue Hour", iconName: "BlueHour", gradient: [Color(red: 0.8, green: 0.5, blue: 0.8), Color(red: 0.12, green: 0.06, blue: 0.18)]),
        .init(id: "night", title: "Night", iconName: "Night", gradient: [Color(red: 0.16, green: 0.18, blue: 0.28), Color(red: 0.05, green: 0.06, blue: 0.12)])
    ]

    var body: some View {
        List {
            Section {
                ForEach(options) { (option: AppIconOption) in
                    Button {
                        applyIcon(option.iconName)
                    } label: {
                        HStack(spacing: 12) {
                            iconPreview(for: option.gradient)
                            Text(option.title)
                                .foregroundStyle(.primary)
                            Spacer()
                        if option.iconName == currentIcon || (option.iconName == nil && currentIcon == nil) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                    .buttonStyle(.plain)
                }
            }

            if let message {
                Section {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func iconPreview(for gradient: [Color]) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.05))
            )
    }

    private func applyIcon(_ name: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            message = "Alternate icons not supported on this device."
            return
        }
        UIApplication.shared.setAlternateIconName(name) { error in
            if let error {
                message = "Icon update failed: \(error.localizedDescription)"
            } else {
                currentIcon = name
                message = "Icon updated."
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppIconView()
            .navigationTitle("App Icon")
    }
}
