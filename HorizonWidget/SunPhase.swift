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
            return "日出"
        case .daytime:
            return "黄金开始"
        case .sunset:
            return "日落"
        case .blueHourStart:
            return "蓝调开始"
        case .blueHourRemaining:
            return "蓝调剩余"
        case .night:
            return "日出"
        }
    }

    var countdownText: String {
        switch self {
        case .preDawn:
            return "7小时34分钟"
        case .daytime:
            return "49分钟30秒"
        case .sunset:
            return "29分钟38秒"
        case .blueHourStart:
            return "5分钟8秒"
        case .blueHourRemaining:
            return "2分钟4秒"
        case .night:
            return "12小时32分钟"
        }
    }
}
