// LeetCodeService.swift
// LeetCodeTracker

import Foundation

class LeetCodeService {
    static let shared = LeetCodeService()

    private let endpoint = "https://leetcode.com/graphql"

    enum LeetCodeError: Error, LocalizedError {
        case networkError(Error)
        case httpError(Int)
        case userNotFound
        case decodingError(Error)

        var errorDescription: String? {
            switch self {
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            case .httpError(let code): return "Server returned HTTP \(code). Please try again."
            case .userNotFound:        return "User not found. Please check the username."
            case .decodingError(let e): return "Data error: \(e.localizedDescription)"
            }
        }
    }

    // MARK: - Public API

    func fetchUserStats(username: String) async throws -> LeetCodeUserStats {
        async let profile     = fetchProfile(username: username)
        async let calendar    = fetchCalendar(username: username)
        async let beats       = fetchBeats(username: username)
        async let recentSubs  = fetchRecentSubmissions(username: username)
        async let extended    = fetchExtendedProfile(username: username)

        let (p, c) = try await (profile, calendar)
        let beatsResult    = await beats
        let recentResult   = await recentSubs
        let extendedResult = await extended

        guard let user = p.matchedUser else {
            throw LeetCodeError.userNotFound
        }

        let subs = user.submitStats?.acSubmissionNum ?? []
        let allQ = p.allQuestionsCount ?? []

        let totalSolved  = subs.first { $0.difficulty == "All" }?.count ?? 0
        let easySolved   = subs.first { $0.difficulty == "Easy" }?.count ?? 0
        let mediumSolved = subs.first { $0.difficulty == "Medium" }?.count ?? 0
        let hardSolved   = subs.first { $0.difficulty == "Hard" }?.count ?? 0

        let totalQ      = allQ.first { $0.difficulty == "All" }?.count ?? 0
        let easyTotal   = allQ.first { $0.difficulty == "Easy" }?.count ?? 0
        let mediumTotal = allQ.first { $0.difficulty == "Medium" }?.count ?? 0
        let hardTotal   = allQ.first { $0.difficulty == "Hard" }?.count ?? 0

        let totalSubs  = subs.first { $0.difficulty == "All" }?.submissions ?? 0
        let acceptance = totalSubs > 0 ? Double(totalSolved) / Double(totalSubs) * 100.0 : 0.0

        let streak         = c.matchedUser?.userCalendar?.streak ?? 0
        let activeDays     = c.matchedUser?.userCalendar?.totalActiveDays ?? 0
        let dailySubs      = parseSubmissionCalendar(c.matchedUser?.userCalendar?.submissionCalendar)
        let longestStreak  = extendedResult?.matchedUser?.userCalendar?.longestStreak ?? streak

        let easyBeats   = beatsResult.first { $0.difficulty == "Easy" }?.percentage   ?? 0
        let mediumBeats = beatsResult.first { $0.difficulty == "Medium" }?.percentage ?? 0
        let hardBeats   = beatsResult.first { $0.difficulty == "Hard" }?.percentage   ?? 0

        let badges = (extendedResult?.matchedUser?.badges ?? []).map {
            Badge(id: $0.id, displayName: $0.displayName, icon: $0.icon, creationDate: $0.creationDate)
        }
        let langStats = (extendedResult?.matchedUser?.languageProblemCount ?? []).map {
            LanguageStat(languageName: $0.languageName, problemsSolved: $0.problemsSolved)
        }
        let recentSubmissions = recentResult.map {
            RecentSubmission(id: $0.id, title: $0.title, titleSlug: $0.titleSlug, timestamp: $0.timestamp)
        }

        return LeetCodeUserStats(
            username:           user.username,
            realName:           user.profile?.realName ?? "",
            userAvatar:         user.profile?.userAvatar ?? "",
            ranking:            user.profile?.ranking ?? 0,
            views:              0,
            countryName:        extendedResult?.matchedUser?.profile?.countryName ?? "",
            githubUrl:          extendedResult?.matchedUser?.profile?.githubUrl ?? "",
            linkedinUrl:        extendedResult?.matchedUser?.profile?.linkedinUrl ?? "",
            totalSolved:        totalSolved,
            easySolved:         easySolved,
            mediumSolved:       mediumSolved,
            hardSolved:         hardSolved,
            totalQuestions:     totalQ,
            easyTotal:          easyTotal,
            mediumTotal:        mediumTotal,
            hardTotal:          hardTotal,
            acceptanceRate:     acceptance,
            easyBeats:          easyBeats,
            mediumBeats:        mediumBeats,
            hardBeats:          hardBeats,
            streak:             streak,
            longestStreak:      longestStreak,
            totalActiveDays:    activeDays,
            reputation:         user.profile?.reputation ?? 0,
            badges:             badges,
            languageStats:      langStats,
            recentSubmissions:  recentSubmissions,
            dailySubmissions:   dailySubs
        )
    }

    // MARK: - Private query helpers

    private func fetchProfile(username: String) async throws -> ProfileQueryData {
        let query = """
        query getUserProfile($username: String!) {
          allQuestionsCount { difficulty count }
          matchedUser(username: $username) {
            username
            profile { realName userAvatar ranking reputation }
            submitStats: submitStatsGlobal {
              acSubmissionNum { difficulty count submissions }
            }
          }
        }
        """
        return try await execute(query: query, variables: ["username": username], as: ProfileQueryData.self)
    }

    private func fetchCalendar(username: String) async throws -> CalendarQueryData {
        let query = """
        query userCalendar($username: String!) {
          matchedUser(username: $username) {
            userCalendar { streak totalActiveDays submissionCalendar }
          }
        }
        """
        return try await execute(query: query, variables: ["username": username], as: CalendarQueryData.self)
    }

    /// Extended profile (country, social, longest streak, badges, languages) — silently fails.
    private func fetchExtendedProfile(username: String) async -> ExtendedProfileQueryData? {
        let query = """
        query getExtendedProfile($username: String!) {
          matchedUser(username: $username) {
            profile { countryName githubUrl linkedinUrl }
            userCalendar { longestStreak }
            badges { id displayName icon creationDate }
            languageProblemCount { languageName problemsSolved }
          }
        }
        """
        return try? await execute(query: query, variables: ["username": username], as: ExtendedProfileQueryData.self)
    }

    /// Beats percentages — silently fails if API doesn't support it.
    private func fetchBeats(username: String) async -> [BeatsStats] {
        let query = """
        query userProblemsSolvedBeats($username: String!) {
          matchedUser(username: $username) {
            problemsSolvedBeatsStats { difficulty percentage }
          }
        }
        """
        let result = try? await execute(query: query, variables: ["username": username], as: BeatsQueryData.self)
        return result?.matchedUser?.problemsSolvedBeatsStats ?? []
    }

    /// Recent accepted submissions — silently fails.
    private func fetchRecentSubmissions(username: String) async -> [RecentSubmissionResponse] {
        let query = """
        query recentAcSubmissions($username: String!) {
          recentAcSubmissionList(username: $username, limit: 15) {
            id title titleSlug timestamp
          }
        }
        """
        let result = try? await execute(query: query, variables: ["username": username], as: RecentSubmissionsQueryData.self)
        return result?.recentAcSubmissionList ?? []
    }

    // MARK: - Submission calendar parser

    private func parseSubmissionCalendar(_ raw: String?) -> [Int] {
        guard let raw,
              !raw.isEmpty,
              let data = raw.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return Array(repeating: 0, count: 365) }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.startOfDay(for: Date())

        return (0..<365).reversed().map { daysAgo in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            let ts = String(Int(date.timeIntervalSince1970))
            return dict[ts] ?? 0
        }
    }

    // MARK: - Year calendar (public, for in-app year picker)

    func fetchCalendarForYear(username: String, year: Int) async -> [Int] {
        let query = """
        query userCalendar($username: String!, $year: Int) {
          matchedUser(username: $username) {
            userCalendar(year: $year) { submissionCalendar }
          }
        }
        """
        let result = try? await execute(
            query: query,
            variables: ["username": username, "year": year],
            as: CalendarQueryData.self
        )
        return parseYearCalendar(result?.matchedUser?.userCalendar?.submissionCalendar, year: year)
    }

    private func parseYearCalendar(_ raw: String?, year: Int) -> [Int] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let yearLength = cal.range(of: .day, in: .year, for: jan1)!.count

        guard let raw, !raw.isEmpty,
              let data = raw.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return Array(repeating: 0, count: yearLength) }

        return (0..<yearLength).map { dayIndex in
            let date = cal.date(byAdding: .day, value: dayIndex, to: jan1)!
            let ts = String(Int(date.timeIntervalSince1970))
            return dict[ts] ?? 0
        }
    }

    // MARK: - Generic executor

    private func execute<T: Decodable>(
        query: String,
        variables: [String: Any],
        as type: T.Type
    ) async throws -> T {
        guard let url = URL(string: endpoint) else { throw LeetCodeError.httpError(-1) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Origin")

        let body: [String: Any] = ["query": query, "variables": variables]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LeetCodeError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw LeetCodeError.httpError(code)
        }

        do {
            let wrapper = try JSONDecoder().decode(GraphQLResponse<T>.self, from: data)
            guard let result = wrapper.data else { throw LeetCodeError.userNotFound }
            return result
        } catch let error as LeetCodeError {
            throw error
        } catch {
            throw LeetCodeError.decodingError(error)
        }
    }
}
