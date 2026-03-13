// WidgetShared.swift
// LeetCodeWidget — shared by all widgets in this extension

import Foundation

struct WidgetData: Codable {
    let username: String
    let totalSolved: Int
    let easySolved: Int
    let mediumSolved: Int
    let hardSolved: Int
    let totalQuestions: Int
    let streak: Int
    let ranking: Int
    let lastUpdated: Date
    /// Last 365 days. Index 0 = oldest, last = today.
    let dailySubmissions: [Int]

    // Custom decoder so old stored data (without dailySubmissions) still loads
    enum CodingKeys: String, CodingKey {
        case username, totalSolved, easySolved, mediumSolved, hardSolved
        case totalQuestions, streak, ranking, lastUpdated, dailySubmissions
    }

    init(username: String, totalSolved: Int, easySolved: Int, mediumSolved: Int,
         hardSolved: Int, totalQuestions: Int, streak: Int, ranking: Int,
         lastUpdated: Date, dailySubmissions: [Int] = []) {
        self.username = username; self.totalSolved = totalSolved
        self.easySolved = easySolved; self.mediumSolved = mediumSolved
        self.hardSolved = hardSolved; self.totalQuestions = totalQuestions
        self.streak = streak; self.ranking = ranking
        self.lastUpdated = lastUpdated; self.dailySubmissions = dailySubmissions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        username       = try c.decode(String.self, forKey: .username)
        totalSolved    = try c.decode(Int.self,    forKey: .totalSolved)
        easySolved     = try c.decode(Int.self,    forKey: .easySolved)
        mediumSolved   = try c.decode(Int.self,    forKey: .mediumSolved)
        hardSolved     = try c.decode(Int.self,    forKey: .hardSolved)
        totalQuestions = try c.decode(Int.self,    forKey: .totalQuestions)
        streak         = try c.decode(Int.self,    forKey: .streak)
        ranking        = try c.decode(Int.self,    forKey: .ranking)
        lastUpdated    = try c.decode(Date.self,   forKey: .lastUpdated)
        dailySubmissions = (try? c.decode([Int].self, forKey: .dailySubmissions)) ?? []
    }
}

func loadWidgetData() -> WidgetData? {
    guard let defaults = UserDefaults(suiteName: "group.com.viralsuchak.leetcodetracker"),
          let raw = defaults.data(forKey: "widgetData")
    else { return nil }
    return try? JSONDecoder().decode(WidgetData.self, from: raw)
}

func emptyWidgetData() -> WidgetData {
    WidgetData(username: "username", totalSolved: 0, easySolved: 0, mediumSolved: 0,
               hardSolved: 0, totalQuestions: 0, streak: 0, ranking: 0, lastUpdated: Date())
}
