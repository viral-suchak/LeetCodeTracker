// LeetCodeHeatmapWidget.swift
// LeetCodeWidget

import WidgetKit
import SwiftUI

// MARK: - Timeline entry & provider

struct HeatmapEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
    let hasData: Bool
}

struct HeatmapProvider: TimelineProvider {
    func placeholder(in context: Context) -> HeatmapEntry {
        HeatmapEntry(date: Date(), data: emptyWidgetData(), hasData: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (HeatmapEntry) -> Void) {
        let stored = loadWidgetData()
        completion(HeatmapEntry(date: Date(), data: stored ?? emptyWidgetData(), hasData: stored != nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HeatmapEntry>) -> Void) {
        let stored = loadWidgetData()
        let entry = HeatmapEntry(date: Date(), data: stored ?? emptyWidgetData(), hasData: stored != nil)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Entry view

struct HeatmapEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    let entry: HeatmapEntry

    var weeksToShow: Int { family == .systemLarge ? currentYearWeeks() : 26 }

    private func currentYearWeeks() -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.startOfDay(for: Date())
        let year = cal.component(.year, from: today)
        let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let dec31 = cal.date(from: DateComponents(year: year, month: 12, day: 31))!
        let jan1WD = cal.component(.weekday, from: jan1) - 1
        let dec31WD = cal.component(.weekday, from: dec31) - 1
        let start = cal.date(byAdding: .day, value: -jan1WD, to: jan1)!
        let end = cal.date(byAdding: .day, value: 6 - dec31WD, to: dec31)!
        return (cal.dateComponents([.day], from: start, to: end).day! + 1) / 7
    }

    var body: some View {
        mainView
    }

    private var mainView: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerRow
            WidgetHeatmapGrid(
                submissions: entry.data.dailySubmissions,
                weeksToShow: weeksToShow,
                colorScheme: colorScheme,
                isFullYear: family == .systemLarge
            )
            if family == .systemLarge {
                statsRow
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var headerRow: some View {
        let totalSubs = entry.data.dailySubmissions.reduce(0, +)
        return HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            HStack(spacing: 3) {
                Text("\(totalSubs)")
                    .font(.subheadline.bold().monospacedDigit())
                Text("submissions in the last year")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            MiniStatCell(value: "\(entry.data.totalSolved)",  label: "Solved",  color: .primary)
            MiniStatCell(value: "\(entry.data.easySolved)",   label: "Easy",    color: .green)
            MiniStatCell(value: "\(entry.data.mediumSolved)", label: "Medium",  color: .orange)
            MiniStatCell(value: "\(entry.data.hardSolved)",   label: "Hard",    color: .red)
        }
        .padding(.top, 4)
    }
}

// MARK: - Heatmap grid (widget-specific, sized to fit)
// isFullYear=true  → current calendar year Jan 1 → Dec 31 (large widget)
// isFullYear=false → rolling weeksToShow weeks ending today (medium widget)

struct WidgetHeatmapGrid: View {
    let submissions: [Int]
    let weeksToShow: Int
    let colorScheme: ColorScheme
    let isFullYear: Bool
    var showMonthLabels: Bool = false

    private var grid: [[Int?]]                          { buildGrid() }
    private var months: [(col: Int, label: String)]     { computeMonthLabels() }

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 2
            let monthH: CGFloat = showMonthLabels ? 12 : 0
            let cell = min(
                (geo.size.width  - gap * CGFloat(weeksToShow - 1)) / CGFloat(weeksToShow),
                (geo.size.height - gap * 6 - monthH) / 7
            )

            ZStack(alignment: .topLeading) {
                if showMonthLabels {
                    ForEach(Array(months.enumerated()), id: \.offset) { _, item in
                        Text(item.label)
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .fixedSize()
                            .offset(x: CGFloat(item.col) * (cell + gap), y: 0)
                    }
                }
                HStack(alignment: .top, spacing: gap) {
                    ForEach(0..<weeksToShow, id: \.self) { col in
                        VStack(spacing: gap) {
                            ForEach(0..<7, id: \.self) { row in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(color(for: grid[col][row]))
                                    .frame(width: cell, height: cell)
                            }
                        }
                    }
                }
                .offset(y: showMonthLabels ? monthH + 2 : 0)
            }
        }
    }

    private func color(for count: Int?) -> Color {
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

    func lcGreen(level: Int) -> Color {
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

    // MARK: - Grid builders

    private func buildGrid() -> [[Int?]] {
        isFullYear ? buildYearGrid() : buildRollingGrid()
    }

    /// Current calendar year: Jan 1 → today, nil for future/out-of-year cells.
    private func buildYearGrid() -> [[Int?]] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.startOfDay(for: Date())
        let year = cal.component(.year, from: today)
        let jan1  = cal.date(from: DateComponents(year: year, month: 1,  day: 1))!
        let dec31 = cal.date(from: DateComponents(year: year, month: 12, day: 31))!
        let jan1WD = cal.component(.weekday, from: jan1) - 1
        let gridStart = cal.date(byAdding: .day, value: -jan1WD, to: jan1)!

        var result: [[Int?]] = Array(repeating: Array(repeating: nil, count: 7), count: weeksToShow)
        for col in 0..<weeksToShow {
            for row in 0..<7 {
                guard let cellDate = cal.date(byAdding: .day, value: col * 7 + row, to: gridStart) else { continue }
                if cellDate < jan1 || cellDate > dec31 || cellDate > today { continue }
                let daysAgo = cal.dateComponents([.day], from: cellDate, to: today).day!
                result[col][row] = daysAgo < submissions.count ? submissions[submissions.count - 1 - daysAgo] : 0
            }
        }
        return result
    }

    /// Rolling window of weeksToShow weeks ending today.
    private func buildRollingGrid() -> [[Int?]] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.startOfDay(for: Date())
        let todayWD = cal.component(.weekday, from: today) - 1

        var result: [[Int?]] = Array(repeating: Array(repeating: Int?(0), count: 7), count: weeksToShow)
        for col in 0..<weeksToShow {
            for row in 0..<7 {
                let daysAgo = (weeksToShow - 1 - col) * 7 + (todayWD - row)
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

    // MARK: - Month labels

    private func computeMonthLabels() -> [(col: Int, label: String)] {
        isFullYear ? yearMonthLabels() : rollingMonthLabels()
    }

    /// One label per month, placed at the column containing the 1st of that month.
    private func yearMonthLabels() -> [(col: Int, label: String)] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.startOfDay(for: Date())
        let year = cal.component(.year, from: today)
        let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let jan1WD = cal.component(.weekday, from: jan1) - 1
        let gridStart = cal.date(byAdding: .day, value: -jan1WD, to: jan1)!
        let fmt = DateFormatter(); fmt.dateFormat = "MMM"

        return (1...12).compactMap { month in
            let first = cal.date(from: DateComponents(year: year, month: month, day: 1))!
            let col = cal.dateComponents([.day], from: gridStart, to: first).day! / 7
            guard col < weeksToShow else { return nil }
            return (col: col, label: fmt.string(from: first))
        }
    }

    /// Month label placed at the column where the month first appears.
    private func rollingMonthLabels() -> [(col: Int, label: String)] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.startOfDay(for: Date())
        let todayWD = cal.component(.weekday, from: today) - 1
        let fmt = DateFormatter(); fmt.dateFormat = "MMM"

        var labels: [(col: Int, label: String)] = []
        var lastMonth = -1
        for col in 0..<weeksToShow {
            let daysAgo = (weeksToShow - 1 - col) * 7 + todayWD
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
}

// MARK: - Helper subview

struct MiniStatCell: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(value).font(.caption.bold().monospacedDigit()).foregroundStyle(color)
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Widget definition

struct LeetCodeHeatmapWidget: Widget {
    let kind = "LeetCodeHeatmapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HeatmapProvider()) { entry in
            if #available(iOS 17.0, *) {
                HeatmapEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                HeatmapEntryView(entry: entry).padding().background()
            }
        }
        .configurationDisplayName("LeetCode Activity")
        .description("Submission heatmap — medium shows 18 weeks, large shows the full year.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Previews

private let sampleSubs: [Int] = (0..<365).map { i in
    [0, 0, 1, 0, 2, 0, 0, 3, 1, 0, 0, 4, 0, 2, 1][i % 15]
}

#Preview(as: .systemMedium) {
    LeetCodeHeatmapWidget()
} timeline: {
    HeatmapEntry(date: .now, data: WidgetData(
        username: "neal_wu", totalSolved: 842,
        easySolved: 312, mediumSolved: 420, hardSolved: 110,
        totalQuestions: 3350, streak: 47, ranking: 12345,
        lastUpdated: .now, dailySubmissions: sampleSubs
    ), hasData: true)
}

#Preview(as: .systemLarge) {
    LeetCodeHeatmapWidget()
} timeline: {
    HeatmapEntry(date: .now, data: WidgetData(
        username: "neal_wu", totalSolved: 842,
        easySolved: 312, mediumSolved: 420, hardSolved: 110,
        totalQuestions: 3350, streak: 47, ranking: 12345,
        lastUpdated: .now, dailySubmissions: sampleSubs
    ), hasData: true)
}
