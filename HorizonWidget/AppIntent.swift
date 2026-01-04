//
//  AppIntent.swift
//  HorizonWidget
//
//  Created by Luca Zhou on 2026-01-03.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Sun photography phases" }
}
