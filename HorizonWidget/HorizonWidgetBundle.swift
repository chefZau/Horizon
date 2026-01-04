//
//  HorizonWidgetBundle.swift
//  HorizonWidget
//
//  Created by Luca Zhou on 2026-01-03.
//

import WidgetKit
import SwiftUI

@main
struct HorizonWidgetBundle: WidgetBundle {
    var body: some Widget {
        HorizonWidget()
        HorizonWidgetControl()
        HorizonWidgetLiveActivity()
    }
}
