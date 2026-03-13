// SharedDataManager.swift
// LeetCodeTracker

import Foundation
import WidgetKit

class SharedDataManager {
    static let shared = SharedDataManager()

    private let suiteName      = "group.com.viralsuchak.leetcodetracker"
    private let widgetDataKey  = "widgetData"
    private let usernameKey    = "savedUsername"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    var savedUsername: String? {
        get { defaults?.string(forKey: usernameKey) }
        set { defaults?.set(newValue, forKey: usernameKey) }
    }

    func saveWidgetData(from stats: LeetCodeUserStats) {
        let data = WidgetData(
            username:          stats.username,
            totalSolved:       stats.totalSolved,
            easySolved:        stats.easySolved,
            mediumSolved:      stats.mediumSolved,
            hardSolved:        stats.hardSolved,
            totalQuestions:    stats.totalQuestions,
            streak:            stats.streak,
            ranking:           stats.ranking,
            lastUpdated:       Date(),
            dailySubmissions:  stats.dailySubmissions
        )
        if let encoded = try? JSONEncoder().encode(data) {
            defaults?.set(encoded, forKey: widgetDataKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadWidgetData() -> WidgetData? {
        guard let raw = defaults?.data(forKey: widgetDataKey) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: raw)
    }
}
