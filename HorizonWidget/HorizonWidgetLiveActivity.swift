//
//  HorizonWidgetLiveActivity.swift
//  HorizonWidget
//
//  Created by Luca Zhou on 2026-01-03.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HorizonWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct HorizonWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HorizonWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension HorizonWidgetAttributes {
    fileprivate static var preview: HorizonWidgetAttributes {
        HorizonWidgetAttributes(name: "World")
    }
}

extension HorizonWidgetAttributes.ContentState {
    fileprivate static var smiley: HorizonWidgetAttributes.ContentState {
        HorizonWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: HorizonWidgetAttributes.ContentState {
         HorizonWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: HorizonWidgetAttributes.preview) {
   HorizonWidgetLiveActivity()
} contentStates: {
    HorizonWidgetAttributes.ContentState.smiley
    HorizonWidgetAttributes.ContentState.starEyes
}
