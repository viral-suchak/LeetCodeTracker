//
//  LeetCodeWidgetBundle.swift
//  LeetCodeWidget
//
//  Created by Viral Suchak on 2/6/26.
//

import WidgetKit
import SwiftUI

@main
struct LeetCodeWidgetBundle: WidgetBundle {
    var body: some Widget {
        LeetCodeWidget()
        LeetCodeHeatmapWidget()
        LeetCodeWidgetLiveActivity()
        if #available(iOS 18.0, *) {
            LeetCodeWidgetControl()
        }
    }
}
