//
//  LeetCodeWidgetLiveActivity.swift
//  LeetCodeWidget
//
//  Created by Viral Suchak on 2/6/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LeetCodeWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct LeetCodeWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LeetCodeWidgetAttributes.self) { context in
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

extension LeetCodeWidgetAttributes {
    fileprivate static var preview: LeetCodeWidgetAttributes {
        LeetCodeWidgetAttributes(name: "World")
    }
}

extension LeetCodeWidgetAttributes.ContentState {
    fileprivate static var smiley: LeetCodeWidgetAttributes.ContentState {
        LeetCodeWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: LeetCodeWidgetAttributes.ContentState {
         LeetCodeWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: LeetCodeWidgetAttributes.preview) {
   LeetCodeWidgetLiveActivity()
} contentStates: {
    LeetCodeWidgetAttributes.ContentState.smiley
    LeetCodeWidgetAttributes.ContentState.starEyes
}
