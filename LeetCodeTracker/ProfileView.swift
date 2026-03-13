// ProfileView.swift
// LeetCodeTracker

import SwiftUI

struct ProfileView: View {
    let stats: LeetCodeUserStats
    let onRefresh: () async -> Void

    @State private var avatarImage: UIImage?
    @State private var isRefreshing = false
    @State private var selectedYear: Int? = nil   // nil = rolling "Current"
    @State private var yearData: [Int: [Int]] = [:]
    @State private var isLoadingYear = false
    @State private var shownYears: [Int] = {
        let cur = Calendar.current.component(.year, from: Date())
        return (max(cur - 4, 2015)...cur).reversed().map { $0 }
    }()

    private var currentCalendarYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                profileHeaderCard
                solvedProblemsCard
                if !stats.badges.isEmpty { badgesCard }
                activityCard
                if !stats.languageStats.isEmpty { languagesCard }
                if !stats.recentSubmissions.isEmpty { recentACCard }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadAvatar() }
    }

    // MARK: - Profile Header

    private var profileHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                // Square avatar
                Group {
                    if let img = avatarImage {
                        Image(uiImage: img).resizable().scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .resizable().scaledToFit()
                            .padding(18)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 5) {
                    Text(stats.realName.isEmpty ? stats.username : stats.realName)
                        .font(.title3.bold())
                        .lineLimit(1)

                    if !stats.realName.isEmpty {
                        Text(stats.username)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if stats.ranking > 0 {
                        HStack(spacing: 4) {
                            Text("Rank").foregroundStyle(.secondary)
                            Text(stats.ranking.formatted()).fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }
                }

                Spacer()

                Button {
                    Task { isRefreshing = true; await onRefresh(); isRefreshing = false }
                } label: {
                    if isRefreshing {
                        ProgressView().scaleEffect(0.75)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(isRefreshing)
            }

            // Info rows
            let hasInfo = !stats.countryName.isEmpty || !stats.githubUrl.isEmpty || !stats.linkedinUrl.isEmpty
            if hasInfo {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    if !stats.countryName.isEmpty {
                        InfoRow(icon: "mappin.circle.fill", text: stats.countryName, color: .red)
                    }
                    if !stats.githubUrl.isEmpty {
                        InfoRow(icon: "chevron.left.forwardslash.chevron.right",
                                text: extractHandle(from: stats.githubUrl), color: .primary)
                    }
                    if !stats.linkedinUrl.isEmpty {
                        InfoRow(icon: "link", text: extractHandle(from: stats.linkedinUrl), color: .blue)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func extractHandle(from url: String) -> String {
        let cleaned = url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return cleaned.components(separatedBy: "/").last ?? cleaned
    }

    // MARK: - Solved Problems

    private var solvedProblemsCard: some View {
        HStack(alignment: .center, spacing: 12) {
            MultiColorArcGauge(
                easySolved:   stats.easySolved,   easyTotal:   stats.easyTotal,
                mediumSolved: stats.mediumSolved, mediumTotal: stats.mediumTotal,
                hardSolved:   stats.hardSolved,   hardTotal:   stats.hardTotal,
                totalSolved:  stats.totalSolved,  totalQuestions: stats.totalQuestions
            )
            .frame(width: 155, height: 155)

            VStack(spacing: 8) {
                DifficultyBox(label: "Easy",  solved: stats.easySolved,   total: stats.easyTotal,   color: lcEasy)
                DifficultyBox(label: "Med.",  solved: stats.mediumSolved, total: stats.mediumTotal, color: lcMedium)
                DifficultyBox(label: "Hard",  solved: stats.hardSolved,   total: stats.hardTotal,   color: lcHard)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Badges

    private var badgesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Badges").font(.subheadline).foregroundStyle(.secondary)
                    Text("\(stats.badges.count)").font(.title3.bold())
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach(stats.badges.prefix(5), id: \.id) { badge in
                    AsyncImage(url: URL(string: badge.icon)) { img in
                        img.resizable().scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    }
                    .frame(width: 56, height: 56)
                }
            }

            if let recent = stats.badges.first {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Most Recent Badge")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(recent.displayName).font(.subheadline.bold())
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Activity (Heatmap)

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Submission count header
            let displaySubs = selectedYear == nil
                ? stats.dailySubmissions
                : (yearData[selectedYear!] ?? [])
            let total = displaySubs.reduce(0, +)
            HStack(spacing: 4) {
                Text("\(total)").font(.headline)
                Text(selectedYear == nil
                     ? "submissions in the past one year"
                     : "submissions in " + String(selectedYear!))
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            // Stats row
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Total active").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 3) {
                        Text("days:").font(.caption).foregroundStyle(.secondary)
                        Text("\(stats.totalActiveDays)").font(.caption.bold())
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 1) {
                    Text("Max").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 3) {
                        Text("streak:").font(.caption).foregroundStyle(.secondary)
                        Text("\(stats.longestStreak)").font(.caption.bold())
                    }
                }
                Spacer()
                // Year picker menu
                Menu {
                    Button("Current") { selectedYear = nil }
                    Divider()
                    ForEach(shownYears, id: \.self) { year in
                        Button(String(year)) { selectYear(year) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isLoadingYear {
                            ProgressView().scaleEffect(0.65)
                                .frame(width: 12, height: 12)
                        } else {
                            Text(selectedYear.map { String($0) } ?? "Current")
                                .font(.caption)
                            Image(systemName: "chevron.down").font(.system(size: 9))
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if let year = selectedYear {
                if isLoadingYear {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 80)
                } else {
                    CompactHeatmap(
                        submissions: yearData[year] ?? [],
                        displayYear: year
                    )
                }
            } else {
                CompactHeatmap(submissions: stats.dailySubmissions, displayYear: nil)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func selectYear(_ year: Int) {
        selectedYear = year
        guard yearData[year] == nil else { return }
        Task {
            isLoadingYear = true
            let data = await LeetCodeService.shared.fetchCalendarForYear(
                username: stats.username, year: year
            )
            yearData[year] = data
            // Remove years with no data from the dropdown (except current year)
            if data.allSatisfy({ $0 == 0 }) && year != currentCalendarYear {
                shownYears.removeAll { $0 == year }
                selectedYear = nil
            }
            isLoadingYear = false
        }
    }

    // MARK: - Languages

    private var languagesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Languages").font(.subheadline.bold())
            ForEach(stats.languageStats.prefix(5), id: \.languageName) { lang in
                HStack(spacing: 6) {
                    Text(lang.languageName)
                        .font(.subheadline)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Capsule())
                    Text("\(lang.problemsSolved)")
                        .font(.subheadline.bold())
                    Text("problems solved")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent AC

    private var recentACCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent AC")
                .font(.subheadline.bold())
                .padding(16)
            Divider()
            ForEach(stats.recentSubmissions.prefix(10), id: \.id) { sub in
                HStack {
                    Text(sub.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text(timeAgo(from: sub.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Divider()
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func timeAgo(from timestamp: String) -> String {
        guard let ts = Double(timestamp) else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: Date(timeIntervalSince1970: ts), relativeTo: Date())
    }

    private func loadAvatar() async {
        guard !stats.userAvatar.isEmpty, let url = URL(string: stats.userAvatar) else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let img = UIImage(data: data) else { return }
        avatarImage = img
    }
}

// MARK: - LeetCode brand colors

private let lcEasy   = Color(red: 0.000, green: 0.722, blue: 0.663)  // #00B8A9
private let lcMedium = Color(red: 1.000, green: 0.631, blue: 0.086)  // #FFA116
private let lcHard   = Color(red: 1.000, green: 0.216, blue: 0.373)  // #FF375F

// MARK: - Multi-color arc gauge

struct MultiColorArcGauge: View {
    let easySolved: Int;    let easyTotal: Int
    let mediumSolved: Int;  let mediumTotal: Int
    let hardSolved: Int;    let hardTotal: Int
    let totalSolved: Int;   let totalQuestions: Int

    private let lineWidth: CGFloat = 13
    private let sweep = 0.75       // 270° arc
    private let rotation = 135.0   // start at 7:30 position

    private var denom: Int { max(easyTotal + mediumTotal + hardTotal, 1) }
    private var ef: Double { Double(easyTotal)   / Double(denom) * sweep }
    private var mf: Double { Double(mediumTotal) / Double(denom) * sweep }
    private var hf: Double { Double(hardTotal)   / Double(denom) * sweep }

    private var ep: Double { easyTotal   > 0 ? Double(easySolved)   / Double(easyTotal)   : 0 }
    private var mp: Double { mediumTotal > 0 ? Double(mediumSolved) / Double(mediumTotal) : 0 }
    private var hp: Double { hardTotal   > 0 ? Double(hardSolved)   / Double(hardTotal)   : 0 }

    var body: some View {
        ZStack {
            // Easy
            arc(from: 0,       to: ef,              color: lcEasy,   dim: true)
            arc(from: 0,       to: ef * ep,          color: lcEasy,   dim: false)
            // Medium
            arc(from: ef,      to: ef + mf,          color: lcMedium, dim: true)
            arc(from: ef,      to: ef + mf * mp,     color: lcMedium, dim: false)
            // Hard
            arc(from: ef + mf, to: sweep,            color: lcHard,   dim: true)
            arc(from: ef + mf, to: ef + mf + hf * hp, color: lcHard, dim: false)

            // Center
            VStack(spacing: 3) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(totalSolved)")
                        .font(.system(size: 26, weight: .bold).monospacedDigit())
                    Text("/\(totalQuestions)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 3) {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold)).foregroundStyle(lcEasy)
                    Text("Solved").font(.caption.bold())
                }
            }
        }
    }

    @ViewBuilder
    private func arc(from start: Double, to end: Double, color: Color, dim: Bool) -> some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(
                dim ? color.opacity(0.18) : color,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: dim ? .butt : .round)
            )
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Difficulty box (right panel)

struct DifficultyBox: View {
    let label: String
    let solved: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption.bold()).foregroundStyle(color)
            Text("\(solved)/\(total)").font(.caption.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Info row (profile header)

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Compact heatmap

struct CompactHeatmap: View {
    /// For rolling mode (displayYear == nil): last 365 days, index 0 = oldest, last = today.
    /// For year mode (displayYear set): index 0 = Jan 1 of that year, last = Dec 31.
    let submissions: [Int]
    let displayYear: Int?   // nil → rolling 26-week view

    @Environment(\.colorScheme) var colorScheme

    private let gap: CGFloat = 2
    private let monthLabelH: CGFloat = 13

    private var isYearMode: Bool { displayYear != nil }

    private var weeksToShow: Int {
        guard let year = displayYear else { return 26 }
        return yearWeekCount(year)
    }

    private var grid: [[Int?]]                      { isYearMode ? buildYearGrid()    : buildRollingGrid() }
    private var months: [(col: Int, label: String)] { isYearMode ? buildYearMonths()  : buildRollingMonths() }

    var body: some View {
        GeometryReader { geo in
            let cell  = min(
                (geo.size.width  - gap * CGFloat(weeksToShow - 1)) / CGFloat(weeksToShow),
                (geo.size.height - gap * 6 - monthLabelH - 4) / 7
            )
            let gridH = 7 * cell + 6 * gap

            ZStack(alignment: .topLeading) {
                HStack(alignment: .top, spacing: gap) {
                    ForEach(0..<weeksToShow, id: \.self) { col in
                        VStack(spacing: gap) {
                            ForEach(0..<7, id: \.self) { row in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(cellColor(for: grid[col][row]))
                                    .frame(width: cell, height: cell)
                            }
                        }
                    }
                }
                // Month labels at BOTTOM
                ForEach(Array(months.enumerated()), id: \.offset) { _, m in
                    Text(m.label)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .offset(x: CGFloat(m.col) * (cell + gap), y: gridH + 4)
                }
            }
        }
        .frame(height: isYearMode ? 80 : 113)
    }

    // MARK: - Colors

    private func cellColor(for count: Int?) -> Color {
        guard let count else { return .clear }
        return lcGreen(level: level(count))
    }

    private func level(_ n: Int) -> Int {
        switch n {
        case 0:     return 0
        case 1...2: return 1
        case 3...5: return 2
        case 6...9: return 3
        default:    return 4
        }
    }

    private func lcGreen(level: Int) -> Color {
        if colorScheme == .dark {
            switch level {
            case 0:  return Color(red: 0.086, green: 0.106, blue: 0.133)
            case 1:  return Color(red: 0.055, green: 0.267, blue: 0.161)
            case 2:  return Color(red: 0.000, green: 0.427, blue: 0.196)
            case 3:  return Color(red: 0.149, green: 0.651, blue: 0.255)
            default: return Color(red: 0.224, green: 0.827, blue: 0.325)
            }
        } else {
            switch level {
            case 0:  return Color(red: 0.922, green: 0.929, blue: 0.941)
            case 1:  return Color(red: 0.608, green: 0.914, blue: 0.659)
            case 2:  return Color(red: 0.251, green: 0.769, blue: 0.388)
            case 3:  return Color(red: 0.188, green: 0.631, blue: 0.306)
            default: return Color(red: 0.129, green: 0.431, blue: 0.224)
            }
        }
    }

    // MARK: - Rolling grid (26 weeks ending today)

    private func buildRollingGrid() -> [[Int?]] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today   = cal.startOfDay(for: Date())
        let todayWD = cal.component(.weekday, from: today) - 1
        let weeks   = weeksToShow

        var result: [[Int?]] = Array(repeating: Array(repeating: Int?(0), count: 7), count: weeks)
        for col in 0..<weeks {
            for row in 0..<7 {
                let daysAgo = (weeks - 1 - col) * 7 + (todayWD - row)
                if daysAgo < 0 {
                    result[col][row] = nil
                } else if daysAgo < submissions.count {
                    result[col][row] = submissions[submissions.count - 1 - daysAgo]
                } else {
                    result[col][row] = 0
                }
            }
        }
        return result
    }

    private func buildRollingMonths() -> [(col: Int, label: String)] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today   = cal.startOfDay(for: Date())
        let todayWD = cal.component(.weekday, from: today) - 1
        let fmt     = DateFormatter(); fmt.dateFormat = "MMM"
        let weeks   = weeksToShow

        var labels: [(col: Int, label: String)] = []
        var lastMonth = -1
        for col in 0..<weeks {
            let daysAgo = (weeks - 1 - col) * 7 + todayWD
            if let date = cal.date(byAdding: .day, value: -daysAgo, to: today) {
                let m = cal.component(.month, from: date)
                if m != lastMonth {
                    labels.append((col: col, label: fmt.string(from: date)))
                    lastMonth = m
                }
            }
        }
        return labels
    }

    // MARK: - Full-year grid (Jan 1 → Dec 31, future cells = nil)

    private func yearWeekCount(_ year: Int) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let jan1   = cal.date(from: DateComponents(year: year, month: 1,  day: 1))!
        let dec31  = cal.date(from: DateComponents(year: year, month: 12, day: 31))!
        let startWD = cal.component(.weekday, from: jan1)  - 1
        let endWD   = cal.component(.weekday, from: dec31) - 1
        let start   = cal.date(byAdding: .day, value: -startWD,      to: jan1)!
        let end     = cal.date(byAdding: .day, value: 6 - endWD,     to: dec31)!
        return (cal.dateComponents([.day], from: start, to: end).day! + 1) / 7
    }

    private func buildYearGrid() -> [[Int?]] {
        guard let year = displayYear else { return [] }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today   = cal.startOfDay(for: Date())
        let jan1    = cal.date(from: DateComponents(year: year, month: 1,  day: 1))!
        let dec31   = cal.date(from: DateComponents(year: year, month: 12, day: 31))!
        let startWD = cal.component(.weekday, from: jan1) - 1
        let gridStart = cal.date(byAdding: .day, value: -startWD, to: jan1)!
        let weeks   = weeksToShow

        var result: [[Int?]] = Array(repeating: Array(repeating: nil, count: 7), count: weeks)
        for col in 0..<weeks {
            for row in 0..<7 {
                guard let cellDate = cal.date(byAdding: .day, value: col * 7 + row, to: gridStart) else { continue }
                if cellDate < jan1 || cellDate > dec31 || cellDate > today { continue }
                let dayIndex = cal.dateComponents([.day], from: jan1, to: cellDate).day!
                result[col][row] = dayIndex < submissions.count ? submissions[dayIndex] : 0
            }
        }
        return result
    }

    private func buildYearMonths() -> [(col: Int, label: String)] {
        guard let year = displayYear else { return [] }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let jan1    = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let startWD = cal.component(.weekday, from: jan1) - 1
        let gridStart = cal.date(byAdding: .day, value: -startWD, to: jan1)!
        let fmt     = DateFormatter(); fmt.dateFormat = "MMM"
        let weeks   = weeksToShow

        return (1...12).compactMap { month in
            let first = cal.date(from: DateComponents(year: year, month: month, day: 1))!
            let col   = cal.dateComponents([.day], from: gridStart, to: first).day! / 7
            guard col < weeks else { return nil }
            return (col: col, label: fmt.string(from: first))
        }
    }
}

// MARK: - Shared card container (used by SubmissionsView in ContentView)

struct CardContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.headline)
            content()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView(
            stats: LeetCodeUserStats(
                username: "viralsuchak",
                realName: "Viral Suchak",
                userAvatar: "",
                ranking: 640812,
                views: 0,
                countryName: "United States",
                githubUrl: "https://github.com/viral5917",
                linkedinUrl: "https://linkedin.com/in/viral-suchak-1703",
                totalSolved: 226,
                easySolved: 95,
                mediumSolved: 120,
                hardSolved: 11,
                totalQuestions: 3865,
                easyTotal: 930,
                mediumTotal: 2022,
                hardTotal: 913,
                acceptanceRate: 69.01,
                easyBeats: 89.4,
                mediumBeats: 88.0,
                hardBeats: 65.2,
                streak: 0,
                longestStreak: 16,
                totalActiveDays: 127,
                reputation: 0,
                badges: [
                    Badge(id: "1", displayName: "100 Days Badge 2025", icon: "", creationDate: nil)
                ],
                languageStats: [
                    LanguageStat(languageName: "Java", problemsSolved: 191)
                ],
                recentSubmissions: [
                    RecentSubmission(id: "1", title: "Fraction to Recurring Decimal",
                                     titleSlug: "fraction-to-recurring-decimal",
                                     timestamp: "\(Int(Date().timeIntervalSince1970 - 3600))"),
                    RecentSubmission(id: "2", title: "LRU Cache",
                                     titleSlug: "lru-cache",
                                     timestamp: "\(Int(Date().timeIntervalSince1970 - 86400))")
                ],
                dailySubmissions: (0..<365).map { _ in Int.random(in: 0..<6) }
            ),
            onRefresh: {}
        )
    }
}
