// Models.swift
// LeetCodeTracker

import Foundation

// MARK: - App-level stats model

struct LeetCodeUserStats: Codable {
    let username: String
    let realName: String
    let userAvatar: String
    let ranking: Int
    let views: Int
    let countryName: String
    let githubUrl: String
    let linkedinUrl: String
    let totalSolved: Int
    let easySolved: Int
    let mediumSolved: Int
    let hardSolved: Int
    let totalQuestions: Int
    let easyTotal: Int
    let mediumTotal: Int
    let hardTotal: Int
    let acceptanceRate: Double
    let easyBeats: Double
    let mediumBeats: Double
    let hardBeats: Double
    let streak: Int
    let longestStreak: Int
    let totalActiveDays: Int
    let reputation: Int
    let badges: [Badge]
    let languageStats: [LanguageStat]
    let recentSubmissions: [RecentSubmission]
    /// Last 365 days of submission counts. Index 0 = oldest, last index = today.
    let dailySubmissions: [Int]
}

// MARK: - Supporting types

struct Badge: Codable {
    let id: String
    let displayName: String
    let icon: String
    let creationDate: String?
}

struct LanguageStat: Codable {
    let languageName: String
    let problemsSolved: Int
}

struct RecentSubmission: Codable {
    let id: String
    let title: String
    let titleSlug: String
    let timestamp: String
}

// MARK: - Shared widget data (stored in App Group UserDefaults)

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
    let dailySubmissions: [Int]
}

// MARK: - GraphQL response wrappers

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
}

// MARK: - Profile query models

struct ProfileQueryData: Decodable {
    let allQuestionsCount: [QuestionCount]?
    let matchedUser: MatchedUser?
}

struct QuestionCount: Decodable {
    let difficulty: String
    let count: Int
}

struct MatchedUser: Decodable {
    let username: String
    let profile: UserProfile?
    let submitStats: SubmitStats?
}

// MARK: - Extended profile query (social links, longest streak, badges, languages — silent-fail)

struct ExtendedProfileQueryData: Decodable {
    let matchedUser: ExtendedMatchedUser?
}

struct ExtendedMatchedUser: Decodable {
    let profile: ExtendedUserProfile?
    let userCalendar: ExtendedUserCalendar?
    let badges: [BadgeResponse]?
    let languageProblemCount: [LanguageStatResponse]?
}

struct ExtendedUserProfile: Decodable {
    let countryName: String?
    let githubUrl: String?
    let linkedinUrl: String?
}

struct ExtendedUserCalendar: Decodable {
    let longestStreak: Int?
}

struct UserProfile: Decodable {
    let realName: String?
    let userAvatar: String?
    let ranking: Int?
    let reputation: Int?
}

struct SubmitStats: Decodable {
    let acSubmissionNum: [SubmissionCount]?
}

struct SubmissionCount: Decodable {
    let difficulty: String
    let count: Int
    let submissions: Int
}

struct BadgeResponse: Decodable {
    let id: String
    let displayName: String
    let icon: String
    let creationDate: String?
}

struct LanguageStatResponse: Decodable {
    let languageName: String
    let problemsSolved: Int
}

// MARK: - Beats query models (separate optional query)

struct BeatsQueryData: Decodable {
    let matchedUser: BeatsMatchedUser?
}

struct BeatsMatchedUser: Decodable {
    let problemsSolvedBeatsStats: [BeatsStats]?
}

struct BeatsStats: Decodable {
    let difficulty: String
    let percentage: Double
}

// MARK: - Calendar query models

struct CalendarQueryData: Decodable {
    let matchedUser: CalendarMatchedUser?
}

struct CalendarMatchedUser: Decodable {
    let userCalendar: UserCalendar?
}

struct UserCalendar: Decodable {
    let streak: Int?
    let totalActiveDays: Int?
    let submissionCalendar: String?
}

// MARK: - Recent submissions query

struct RecentSubmissionsQueryData: Decodable {
    let recentAcSubmissionList: [RecentSubmissionResponse]?
}

struct RecentSubmissionResponse: Decodable {
    let id: String
    let title: String
    let titleSlug: String
    let timestamp: String
}
